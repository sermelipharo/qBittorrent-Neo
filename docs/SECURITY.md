# Security review of the network-facing parts

Scope: everything this fork adds around qBittorrent 5.2.4. qBittorrent's
own networking (libtorrent, WebUI, RSS, search plugins, DNS updater, SMTP,
GeoIP download, tracker list download) is used unmodified and inherits
upstream's security properties and fixes.

## The bridge (core/)

* No listening sockets, ports, IPC endpoints or files are added. The C API
  is only reachable from inside the app process.
* Requests carry JSON built by the app. Parsing uses `QJsonDocument`;
  malformed input yields an `InvalidArgument` reply. Handlers validate what
  qBittorrent's WebAPI validates (category names, tag names, file/folder
  names for renames, tracker tiers, web seed schemes http/https/ftp, peer
  addresses, file indexes, rule names) and report errors instead of
  asserting. Exceptions never cross the C boundary.
* Every request is answered exactly once, also when the core stops, so no
  Swift continuation leaks and no callback context is used after free
  (the reply context is retained by Swift until the callback releases it).
* Thread safety: Qt objects are only touched on the core thread; replies
  and events copy data before invoking callbacks.

## New network operations

* `fetchTrackerFavicon`: derives `http(s)://<ip or last two host labels>/
  favicon.ico` (then `.png`) from a tracker URL, like qBittorrent's tracker
  filter; downloads through `Net::DownloadManager` (general-purpose proxy
  setting, TLS validation as configured), with a 64 KiB size limit;
  responses that look like HTML are rejected. Bytes are returned unparsed;
  the app decodes them with `NSImage`.
* `addTorrent(...cookie:)`: the cookie is stored in the download manager's
  cookie jar for that URL only, as qBittorrent's WebAPI `torrents/add` does.
* `searchDownloadTorrent`: uses the plugin's own `download_torrent`
  (nova2dl, qBittorrent's code) only when the result belongs to an
  installed plugin; otherwise the URL is added like any other link.

## Secrets

* WebUI password: `setPreferencesJson("web_ui_password")` hashes with
  qBittorrent's PBKDF2 (`Utils::Password::PBKDF2`, ≥ 6 characters);
  `setPreferences` only accepts an empty or already hashed value, so a
  plain-text password can never be stored by mistake.
* UI-lock password: PBKDF2 hash/verify in the core; only the hash is kept.
* SMTP, proxy and DynDNS passwords are stored by qBittorrent's settings as
  upstream does (plain in the profile's settings file); they are returned to
  the app for the preferences pages only.

## Defaults that matter

* WebUI: started in qBittorrent's GUI mode — disabled unless enabled in the
  preferences, and it refuses logins while no password is set (no temporary
  password is generated or printed).
* External programs run on torrent added/finished use qBittorrent's
  argument splitting with per-argument placeholder substitution and no
  shell, so torrent names cannot inject commands.
* The app's default profile is separate from qBittorrent's
  (`~/Library/Application Support/mk.lex.qbittorrentneo`).
* Hardened runtime stays on; `disable-library-validation` is set so the
  embedded Qt frameworks load in ad-hoc builds (all embedded code is signed
  with the app's identity by `scripts/deploy-qt.py`).

## Residual risks / follow-ups

* Search plugins are Python scripts executed with the user's privileges
  (upstream design); installing one from a URL trusts that source.
* Homebrew Qt/OpenSSL/ICU builds are bundled as-is; security updates
  require rebuilding the app.
* Images (tracker favicons, RSS icons) are decoded by AppKit; size is
  capped at 64 KiB for favicons, RSS icons follow qBittorrent's limits.
