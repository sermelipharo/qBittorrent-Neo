# Parity status

What the SwiftUI app can do through the in-process qBittorrent core. The
behaviour behind every call is qBittorrent 5.2.4's own code; the bridge
only converts data. "Verified" means exercised against a real session
(smoke tool `core/tools/smoke.c` and/or the app with a scratch profile).

## Core client calls (`CoreClient`)

| Area | Calls | Status |
|---|---|---|
| Lifecycle | start (profile dir, WebUI port override), shutdown, event listener, version, buildInfo | Done, verified |
| Transfer list | syncMainData (record diffs: torrents, categories, tags, trackers, server state), resetMainData | Done, verified |
| Properties | properties, trackers (+ DHT/PeX/LSD rows, endpoints), webSeeds, files (+ availability), pieceStates, pieceAvailability, peers (+ host names, countries), exportTorrent | Done, verified (General, Trackers, Peers, HTTP Sources, Content, Speed tabs) |
| Adding | addTorrent (magnet / hash / http(s) URL / file / bytes, all options, extra trackers and web seeds, cookie), fetchMetadata (+ cancel), saveFetchedMetadata, duplicate handling (merge trackers) | Done, verified (Sintel magnet through the add dialog) |
| Torrent actions | start, stop, force start, remove (+ content: delete or trash per setting), recheck, reannounce, set location / save path / download path, rename torrent / file / folder, file priority, auto TMM, per-torrent limits, share limits, super seeding, sequential, first/last piece, DHT/PeX/LSD per torrent, queue up/down/top/bottom | Done (stop / remove-with-files verified) |
| Trackers, peers, web seeds | add / edit / remove / replace trackers, add peers, ban peers, add / edit / remove web seeds | Done |
| Categories, tags | list, create, edit (save/download paths, share limits), remove, set; tags list/create/delete/add/remove | Done |
| Global transfer | server state, alternative limits, global limits, speed history | Done, verified |
| Log | main log (level filter), peer log, clear | Done, verified |
| Preferences | all 224 fields of the app's `Preferences` record, read and write (only changed fields are written) | Done, verified (read all pages, write speed/BitTorrent/RSS fields) |

## Feature clients

| Client | Calls | Status |
|---|---|---|
| `AppInfoClient` | network interfaces / addresses, cookies get/set, test e-mail, WebUI password/username (`setPreferencesJson`), WebUI status, UI-lock PBKDF2 hash/verify, tracker favicons | Done |
| `RSSClient` | tree (with/without articles), articles, add folder/feed, set URL, per-feed refresh interval, remove, move, mark read, refresh, rules CRUD/rename, matching articles, preview of unsaved rule, clear episode history, import (JSON or legacy) / export (JSON, legacy), expression and episode-filter validation | Done, verified (feed, rule, validation) |
| `SearchClient` | Python status, plugins list, install (URL/path), uninstall, enable, update all, start (all / enabled / named plugins, max 5 concurrent), stop, status, paged results, delete, download through the plugin (nova2dl) then add | Done, verified (plugin install, search run) |
| `CreatorClient` | add task (v1/v2/hybrid, piece size, private, trackers, web seeds, comment, source, start seeding), list, task, .torrent bytes, delete, automatic piece size, piece count | Done, verified |

## Events (`CoreEvent`)

Emitted: torrentAdded, torrentFinished, torrentMetadataReceived,
torrentRemoved, fullDiskError, addTorrentFailed, duplicateTorrent,
allTorrentsFinished, rssUpdated (coalesced), searchUpdated,
searchPluginsUpdated, creatorTaskUpdated (polled 1 s while tasks run), log,
preferencesChanged.

Not emitted (no qBittorrent signal): torrentError (I/O errors arrive as
fullDiskError, as in qBittorrent's GUI), rssTorrentDownloaded,
externalAddressChanged, shutdownRequested.

## Application-level behaviour (from qBittorrent's application layer)

Ported into `NeoApplication`: profile and settings migration (`upgrade.cpp`),
first-run defaults, translation of core messages (`:/lang`), file logger,
"Run external program" on added/finished torrents (same argument splitting
and placeholders, no shell), e-mail notification on completion, WebUI
(GUI-mode semantics: no temporary password; refuses logins until a password
is set), RSS session and auto-downloader, watched folders, GeoIP, reverse
DNS, AddTorrentManager (download of .torrent URLs, auto-deletion of added
.torrent files).

Handled by the SwiftUI app instead (as in the sibling project): notifications,
Dock badge/menu, menu bar extra, "On downloads done" actions with
confirmation, UI lock, GUI-only preferences (UserDefaults).

## Differences and gaps

* `TorrentCreatorParams.ignoreShareLimits` is ignored (qBittorrent's
  creation manager has no such option); `optimizeAlignment` and
  `paddingFileLimit` only exist for libtorrent 1.2 and are ignored.
* `diskIoType`: qBittorrent's "Default" has no case in the app and is shown
  as memory-mapped (unchanged unless the user picks another value).
* `useSubcategories` is always true (qBittorrent 5.2 removed the option).
* `webuiStatus().temporaryPassword` is always empty (GUI-mode WebUI).
* `clearLog` hides earlier messages (qBittorrent's logger has no clear).
* Duplicate torrents added from an http(s) URL report a `Conflict` error
  without the existing torrent's hash (the URL is downloaded first).
* Speed history: 1 s samples for 30 minutes, 30 s averages beyond.
* `TrackerEntry.status` reports `updating` for trackers being announced
  (qBittorrent's GUI shows "Updating..." for the same flag).
* Single-instance handling and command-line torrent arguments of
  qBittorrent (ApplicationInstanceManager) are not used; macOS delivers
  files and magnet links to the running app.
* App changes vs. the sibling project: `QtCoreClient` replaces the UniFFI
  `App`; About texts; speed graph buckets by timestamp; three table cells
  take their state as parameters instead of `@Environment` (accessibility
  hit-tests could build them outside the window environment); debug
  verification hooks.

## Not done yet

* Automated tests for the bridge beyond the smoke tool (e.g. a scripted
  `QBT_UI_SCRIPT` scenario runner like the sibling project's UIDriver).
* Release build/notarization pipeline, Sparkle-style updates, universal
  (x86_64) build.
* Localization of new About strings; translation of core messages follows
  the `locale` preference (qBittorrent's `.qm` files are embedded).
* Performance tuning for very large sessions (the transfer-list diff
  serializes every torrent once per refresh, like qBittorrent's WebAPI).
