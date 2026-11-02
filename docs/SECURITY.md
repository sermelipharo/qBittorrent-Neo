# Security review of the network-facing parts

Scope: everything this fork adds around qBittorrent 5.3.0. qBittorrent's
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
* `checkPort` (Settings › Network › **Test Port**): `GET
  https://portcheck.transmissionbt.com/<port>`, the service Transmission
  uses; it connects back to the caller's address and answers `1` (reachable)
  or `0`. Verified 2026-10-15: https works and the body is a single digit;
  the Transmission project publishes no privacy policy for the service.
  * Privacy: it sends the public IP address and the listening port to a
    third party, so it runs only when the user clicks the button (never on
    launch, on a timer or when settings change), and the footnote next to
    the button names the service.
  * The URL is a constant with https (certificates validated as
    configured); only the port is appended, validated as 1–65535 in the
    bridge.
  * `Net::DownloadManager` with the general-purpose proxy setting (the
    service then tests the proxy's address); response limit 16 bytes; the
    reply fails after 20 s even if Qt's transfer timeout hasn't fired.
  * Anything but a successful download whose trimmed body is `0` or `1` is
    an error; the body is never shown or logged.
* `addTorrent(...cookie:)`: the cookie is stored in the download manager's
  cookie jar for that URL only, as qBittorrent's WebAPI `torrents/add` does.
* `searchDownloadTorrent`: uses the plugin's own `download_torrent`
  (nova2dl, qBittorrent's code) only when the result belongs to an
  installed plugin; otherwise the URL is added like any other link.

## Lua plugins (qBittorrent 5.3's `PluginsEngine`, `core/src/api_plugins.cpp`)

qBittorrent 5.3 (#24485) runs user-installed Lua plugins on torrent events
and from its Plugins menu. Their API includes `qBittorrent.exec` (start a
program) and `qBittorrent.sendMail`, so an enabled plugin is code execution
as the user. qBittorrent Neo uses upstream's engine unmodified
(`qbittorrent/src/base/plugins`, Lua 5.5 and LuaBridge 3 from
`src/base/3rdparty`); the aim is that only plugins the user chose can run
and that they cannot be planted by others, not to make a hostile plugin
safe.

Threats: another local account or process planting or replacing plugin
files; a remote party (WebAPI client, RSS feed, torrent, search plugin)
getting a plugin installed or the engine switched on; a buggy or hostile
plugin hanging or bloating the app.

What upstream's engine does (unchanged):
* Each plugin gets its own Lua state with only the base, string, table,
  math, utf8 and coroutine libraries (no `io`, `os`, `debug`, `package`);
  `load`, `loadfile`, `dofile`, `collectgarbage`, `getmetatable`,
  `setmetatable`, `raw*`, `warn` and `string.dump` are removed. Files are
  read up to 1 MiB.
* A count hook (every 100 VM instructions) raises "Timed out." once a call
  has run for 1 s.
* `exec` splits the command line like "Run external program" and starts the
  program detached without a shell; `sendMail` uses the e-mail notification
  settings.
* Installing needs an absolute local path; an update needs a higher
  `VERSION`; new plugins are installed disabled. Installs, updates,
  uninstalls, load failures and failed calls are logged.
* qBittorrent 5.3's WebAPI and Web UI have no plugin endpoints.

**Unlike the sibling qBit NeoRS, upstream's engine has no instruction or
memory budget and no isolation from the core.** Plugins run synchronously
on the core thread inside session signal handlers, so a slow plugin stalls
the whole core (transfers, the app's requests) for up to its 1 s limit per
event. The 1 s limit is a Lua error that the plugin can catch with `pcall`
(which upstream leaves in place), and C functions such as string pattern
matching are not interrupted, so a hostile plugin can hang the app
indefinitely. Each Lua state uses the default allocator without a cap, so a
plugin can exhaust memory. There are no per-call limits on log lines,
programs or e-mails, and individual `exec`/`sendMail` calls are not logged.
These cannot be fixed from the bridge without editing `qbittorrent/`.

What qBittorrent Neo adds around it (no upstream change):
* A global switch, Settings › Privacy › Plugins › **Enable plugins**
  (`AdvancedPrefs.pluginsEnabled`), stored as `Neo/PluginsEnabled` in the
  profile's `qBittorrent.ini`, off by default. It is not a WebAPI
  preference, so a WebAPI client can neither read nor change it. While it
  is off `PluginsEngine` is never constructed: no Lua state exists, no
  plugin file is read and no session signal is connected; every plugin call
  of the bridge is refused ("Plugins are turned off."). Turning it off at
  run time frees the engine on the core thread between events (never from
  inside a Lua call); pending install/uninstall requests then fail.
* Before the engine starts, the plugins folder (`<profile>/qBittorrent/data/
  plugins`, created 0700 when missing) and every `*.lua` file in it must be
  owned by the user running the app and not group/world-writable, and the
  files must be regular files. Otherwise the engine is not started, the
  reasons are logged and shown in the Plugins window, and the user has to
  fix the permissions and turn the switch off and on. The check uses
  `stat` before upstream opens the files (a check-then-use window remains;
  an attacker who can win it already owns files of the user).
* Installation only from a local `.lua` file the user picks or drops in
  the Plugins window: an absolute path (`://` refused), an existing regular
  file, not a file inside the plugins folder itself (upstream would delete
  it before copying). The installed copy is set to 0600, since `QFile::copy`
  keeps the source's permissions. A second request for the same file or ID
  while one is pending is refused (its failure signal would otherwise be
  taken for the first request's).
* The window warns, as the sibling does: "An enabled plugin can run
  programs and send e-mail as you. Install plugins only from people you
  trust."
* The macOS app is not sandboxed (it already runs external programs for
  "Run external program"), so `exec` adds no capability the user did not
  already grant through that setting. `config/plugins.json` (enabled flags)
  lives next to `qBittorrent.ini`, which already holds that program's
  command line, so it is not checked separately.

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
* WebUI theme (qBittorrent Neo restyle of `src/webui/www`): no HTML
  changed. The two script changes add no injection paths: `progressbar.js`
  writes the percentage with `textContent` from a number clamped to 0-100
  and sets only fixed style values plus a numeric width; `client.js` only
  reads `matchMedia` to start with the filters sidebar hidden. No external
  requests (system font stack, no web fonts or CDNs); the new icons are
  `data:` SVG URIs in CSS, which the server's CSP already allows
  (`img-src 'self' data:`); no inline scripts added, so the CSP
  (`default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self'
  'unsafe-inline'; …`) needs no change. The redrawn icons in
  `private/images` are static SVGs loaded through `<img>` and CSS
  backgrounds (where scripts never run): only paths, shapes and a `<style>`
  block with colors, no scripts, event attributes, links, `<image>` or
  `url()` references.
* External programs run on torrent added/finished use qBittorrent's
  argument splitting with per-argument placeholder substitution and no
  shell, so torrent names cannot inject commands.
* The app's default profile is separate from qBittorrent's
  (`~/Library/Application Support/mk.lex.qbittorrentneo`). With
  `--profile` the GUI settings (including the UI-lock password hash) are
  kept in that profile, not in the app's regular `UserDefaults`.
* The IP geolocation database is loaded, and downloaded from db-ip.com when
  missing or older than a month (qBittorrent's GeoIPManager), only when a
  peer list is first shown or the WebUI is enabled, not at every start.
* Hardened runtime stays on; `disable-library-validation` is set so the
  embedded Qt frameworks load in ad-hoc builds (all embedded code is signed
  with the app's identity by `scripts/deploy-qt.py`). Release builds sign
  every embedded binary with the hardened runtime and a secure timestamp,
  ship only the OpenSSL TLS plug-in and carry no absolute run paths, so no
  library outside the bundle (e.g. Homebrew's) can be loaded instead.

## Residual risks / follow-ups

* Search plugins are Python scripts executed with the user's privileges
  (upstream design); installing one from a URL trusts that source.
* Lua plugins, once enabled, can hang the core or exhaust memory (see the
  Lua plugins section: upstream's engine has no enforceable time, instruction
  or memory budget). The switch is off by default.
* Homebrew Qt/OpenSSL/ICU builds are bundled as-is; security updates
  require rebuilding the app.
* Images (tracker favicons, RSS icons) are decoded by AppKit; size is
  capped at 64 KiB for favicons, RSS icons follow qBittorrent's limits.
