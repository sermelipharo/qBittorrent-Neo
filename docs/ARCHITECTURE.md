# qBittorrent Neo — architecture

qBittorrent Neo is qBittorrent 5.2.4 with its Qt Widgets GUI replaced by a
native SwiftUI app. The whole qBittorrent application core runs inside the
app process; the SwiftUI code talks to it through a narrow C interface.

```
┌──────────────────────────────────────────────────────────────────────┐
│ apps/macos (SwiftUI, Swift 6, main thread / Swift concurrency)       │
│  AppModel ─ stores ─ windows          DemoClient (previews, --demo)  │
│        │ CoreClient / AppInfoClient / RSSClient / SearchClient /     │
│        │ CreatorClient protocols                                     │
│  QtCoreClient ── CoreBridge (JSON <-> Codable records)               │
└────────┬───────────────────────────────────────▲─────────────────────┘
         │ qbtn_core_call(method, json, reply)   │ reply / event callbacks
┌────────▼───────────────────────────────────────┴─────────────────────┐
│ core/ libqbtneocore.dylib (C++20, Qt 6)          "core thread"       │
│  bridge.cpp: pthread + QCoreApplication event loop                   │
│  CoreHost: Registry of handlers (api_*.cpp), MainDataTracker,        │
│            EventHub, speed history                                   │
│  NeoApplication: profile, settings, translations, file logger,       │
│            component start-up/cleanup (port of src/app/application)  │
├──────────────────────────────────────────────────────────────────────┤
│ qbittorrent/src/base (qbt_base.a) + src/webui (qbt_webui.a), unmodified│
│  BitTorrent::Session ─ Preferences ─ RSS ─ SearchPluginManager ─     │
│  TorrentCreationManager ─ TorrentFilesWatcher ─ Net::* ─ WebUI       │
├──────────────────────────────────────────────────────────────────────┤
│ libtorrent-rasterbar 2.0 (static) ─ Boost.Asio ─ OpenSSL             │
└──────────────────────────────────────────────────────────────────────┘
```

## Repository layout

* `qbittorrent/` — qBittorrent 5.2.4, imported with `git subtree` (full
  history; the `upstream` branch is `release-5.2.4`). Never edited. Upstream
  updates: `git fetch https://github.com/qbittorrent/qBittorrent.git
  refs/tags/release-X:refs/tags/release-X` then `git subtree merge
  --prefix=qbittorrent release-X`.
* `core/CMakeLists.txt` — a top-level CMake project that includes
  qBittorrent's own CMake modules (`CheckPackages`, `CommonConfig`) and adds
  `qbittorrent/src/base` and `qbittorrent/src/webui` as subdirectories with
  `GUI=OFF`, exactly like a `qbittorrent-nox` build, then builds the bridge.
  It also compiles two unmodified files of `src/app` (`filelogger.cpp`,
  `upgrade.cpp`) and the `searchengine.qrc` / translation resources that the
  application layer normally links in. The only file written into the
  vendored tree is the generated `src/base/version.h`, which upstream also
  generates there (and ignores in git).
* `core/include/qbtneo.h` + `module.modulemap` — the C API, imported by
  Swift as module `QBTNeoCore`.
* `core/src/` — the bridge (see below). `core/tools/smoke.c` is a command
  line client of the C API used for headless tests.
* `apps/macos/` — the SwiftUI app (copied from the sibling Rust project
  qBit NeoRS) with `Core/Bridge/` (Swift side of the bridge) and
  `Generated/CoreTypes.swift` (records/enums, see below).
* `scripts/` — `build-deps.sh` (libtorrent), `build-core.sh` (CMake build),
  `deploy-qt.py` (embedding), `import-types.py` (record types),
  `window-shot.swift` / `capture.sh` (window captures of test runs).

## Why a C API with JSON (and not Swift C++ interop or Objective-C++)

* qBittorrent's headers are Qt-heavy (moc'd QObjects, implicit sharing,
  `QString`, templates, `nonstd::expected`). Swift's C++ interop cannot
  import moc-generated classes meaningfully, would leak Qt/libtorrent types
  and thread-affinity rules into Swift, and slows Swift builds considerably.
* Every Qt object must be used on its own thread. A message-passing
  interface makes that structural: Swift can only *post a request*; nothing
  in Swift can touch a Qt object by mistake.
* The app's data model already exists as plain Swift records (the
  `CoreClient` contract of the sibling project). JSON keyed by the Swift
  property names decodes straight into them with `Codable`, so the SwiftUI
  code compiles unchanged and DemoClient keeps working.
* Objective-C++ would add a third type system (NSDictionary/NSObject
  wrappers for ~80 record types) without removing any of the marshalling.
* Cost: a JSON encode/decode per call. Typical replies are a few KB; the
  transfer-list diff sends only changed torrents. Measured with a real
  session this is far below the 1.5 s refresh interval.

## The C API (`qbtneo.h`)

```c
qbtn_core *qbtn_core_start(config_json, len, on_event, ctx, &error);
uint64_t   qbtn_core_call(core, "method", args_json, len, reply_fn, ctx);
void       qbtn_core_cancel(core, request_id);
void       qbtn_core_shutdown(core);   // saves resume data, joins the thread
```

* `qbtn_core_start` creates a pthread (8 MiB stack) that constructs
  `NeoApplication` (a `QCoreApplication`), `EventHub` and `CoreHost`, then
  runs `exec()`. That thread is Qt's "main thread" for the whole core.
  The call blocks until `BitTorrent::Session` exists (torrents keep loading
  asynchronously afterwards); Swift calls it off the main actor.
* `qbtn_core_call` parses the arguments, then posts a functor to `CoreHost`
  with `QMetaObject::invokeMethod(..., Qt::QueuedConnection)`. On the core
  thread `CoreHost::dispatch` looks the method up in the `Registry` and runs
  the handler. Handlers are either synchronous (return a `QJsonValue`) or
  asynchronous (complete a `Reply` later: libtorrent futures, downloads,
  metadata retrieval, plugin installs). Exceptions (`ApiError`) become error
  replies with a status code that Swift maps to `QbtError`.
* Exactly-once replies: `Reply` is a shared state; the first completion
  wins, and if a queued request is dropped (core stopping) the destructor of
  the last copy completes it with `QBTN_CANCELLED`.
* `qbtn_core_cancel` runs the handler's cancel hook on the core thread
  (e.g. `Session::cancelDownloadMetadata` for the add dialog) and completes
  the request with `QBTN_CANCELLED` (Swift: `CancellationError`).
* Events: `EventHub` connects to Session / AddTorrentManager / Logger /
  Preferences / RSS / search / creator signals and calls `on_event` with
  JSON shaped like Swift's synthesized `Codable` of `CoreEvent`
  (`{"torrentFinished":{"hash":..,"name":..}}`). Log lines are forwarded
  from the logging thread directly; RSS bursts are coalesced (300 ms).
* Shutdown: `QCoreApplication::quit` is queued; after `exec()` returns,
  pending requests are cancelled and `NeoApplication::cleanup()` deletes the
  components in qBittorrent's order (WebUI, RSS, watcher, AddTorrentManager,
  Session — which saves resume data — then networking, preferences,
  settings, search, logger, profile).

## Swift side (`apps/macos/QBTNeo/Core/Bridge`)

* `CoreBridge` owns the handle. `call` (synchronous) retains a `ReplyBox`,
  posts the request and waits on a semaphore (30 s timeout); `callAsync`
  suspends on a checked continuation and forwards Swift task cancellation to
  `qbtn_core_cancel`. Neither ever runs Qt code on the calling thread. The
  facade's synchronous calls are cheap reads/writes of in-memory state;
  bulky ones (`syncMainData`, `files`, `peers`) are already made off the
  main actor by the app (`CoreCall.run`).
* `QtCoreClient` implements `CoreClient`, `AppInfoClient`, `RSSClient`,
  `SearchClient` and `CreatorClient` by name/argument pairs that match the
  handlers in `core/src/api_*.cpp`.
* `Generated/CoreTypes.swift` is produced by `scripts/import-types.py` from
  the sibling project's UniFFI bindings: the same structs/enums (field names,
  initializers, doc comments) without FFI glue, plus `Codable` (records
  decode leniently: missing keys fall back to zero/empty/nil) and `Sendable`.
  Re-run the script when the app's record types change.

## Threads and blocking

* Core thread: Qt event loop, all qBittorrent objects. libtorrent runs its
  own network/disk threads; qBittorrent's resume-data storage and search
  processes run on their own threads/processes as upstream.
* The main thread only blocks for synchronous calls, which the core answers
  between events (microseconds when idle). Long operations (adding from a
  URL, metadata, peer lists, piece states, file availability, plugin
  installs, piece counting) are asynchronous on the core side.

## Data mapping (core → records)

Values keep qBittorrent's WebAPI semantics (bytes, bytes/s, Unix seconds,
`-1` unknown, ETA 8640000 = infinity), produced by code ported from the
WebAPI controllers (`serialize_torrent.cpp`, `TorrentsController`,
`SyncController`, `AppController::preferencesAction`), but with camelCase
keys and enum case names instead of WebAPI strings/integers:

* `syncMainData` — `MainDataTracker` keeps the last sent JSON per torrent /
  category / tag / tracker and returns only differences (`fullUpdate` after
  `resetMainData`). The tracker→torrents map is rebuilt only after tracker
  changes.
* `preferences` / `setPreferences` — 224 fields in 8 groups; writing applies
  only fields that changed (see `api_preferences.cpp`).
* Speed graph — sampled from `SessionStatus` whenever the session publishes
  statistics (`statsUpdated`, every refresh interval; no timer of its own):
  every sample of the last 30 minutes and 30 s averages for 24 hours
  (~230 KB); replies are averaged to at most ~600 points (the app buckets
  by timestamp).

## Profiles and paths

* `--profile <dir>` (or the `profileDir` config) selects a qBittorrent
  "custom profile": everything lives in `<dir>/qBittorrent/{config,data,
  cache,downloads}`, including the default save path.
* Without it the app uses `~/Library/Application Support/mk.lex.qbittorrentneo`
  as profile root (never qBittorrent's own profile) and sets the default save
  path to the user's Downloads folder on first run.
* GUI-only settings: `UserDefaults` of the app, or with `--profile` the
  file `<dir>/qBittorrent/config/gui-preferences.plist`; saved search tabs:
  `<root>/qBittorrent/data/SearchUI` (as qBittorrent). The icons and colors
  of categories and tags are GUI settings too (`LabelAppearanceStore`, keyed
  by name), so `categories.json` and the WebAPI stay unchanged; the SF Symbol
  names searched by the icon picker are bundled in
  `Resources/SFSymbolNames.txt` (`scripts/make-symbol-list.py`).
* The IP geolocation database (~8 MB in memory) is loaded on first use (a
  peer list) instead of at start-up, or at start-up when the WebUI is
  enabled (its peer lists use it too).

## Packaging

`scripts/deploy-qt.py` (an Xcode post-build phase) copies
`libqbtneocore.dylib` into `Contents/Frameworks` (install name
`@rpath/...`), recursively copies its non-system dependencies (Qt
frameworks, OpenSSL, ICU, GLib, ...) rewriting references to
`@executable_path/../Frameworks`, copies the OpenSSL TLS backend (Qt loads
every TLS plug-in it finds; the others are unused), SQLite and
network-information Qt plug-ins to `Contents/PlugIns`, writes
`Contents/Resources/qt.conf`, removes absolute run paths and signs
everything with the build's identity (`Signing.xcconfig` / gitignored
`Local.xcconfig`; Release: hardened runtime and secure timestamp). The Qt
part is skipped while its inputs are unchanged.

## Test runs

Debug builds understand `QBT_VERIFY_*` variables (`App/DebugVerification.swift`):
`QBT_VERIFY_ACCEPT_ADD=1` confirms add dialogs, `QBT_VERIFY_TABS=<s>` cycles
the properties tabs, `QBT_VERIFY_WINDOWS=rss,search,settings,...` opens
windows. While any of them is set, windows stay at normal level, almost
transparent and click-through; `scripts/capture.sh <pid> <prefix> <dir>`
makes them opaque for the moment of a capture (`QBT_UI_DIR=<dir>`).
Launch with `open -g -n`, never activate, quit with
`osascript -e 'tell application id "mk.lex.qbittorrentneo" to quit'`.

### Scripted UI scenarios

`QBT_UI_SCRIPT=<scenario>` (Debug) runs a scenario of `App/UIScenarios*.swift`
through the real UI: `UIDriver` finds controls in the app's own
accessibility tree and drives them with synthesized `NSEvent`s (no
Accessibility permission, the app is never activated, windows stay at
alpha 0.01 and click-through). `scripts/ui-scenario.sh <app> <profile>
<ui-dir> <scenario> [VAR=value...]` starts the app with `open -g -n`,
captures the app's windows whenever the scenario asks for a shot
(`shot-<name>.req` -> `window-shot.swift` -> `.ack`), waits for the app to
quit and prints the `UIDRIVER: PASS/FAIL` lines. Scenarios: `options-set` /
`options-verify` (Torrent Options DHT/PeX/LSD switches, relaunch; needs
`QBT_UI_TORRENT=<public.torrent>:<private.torrent>` named
`uiverify-public.bin` / `uiverify-private.bin`), `lock-quit` (UI lock, quit
with a wrong and then the right password), `search-live` /
`search-restore` (needs an installed search plugin; `QBT_UI_QUERY`),
`bunny` (real download of a magnet, `QBT_UI_MAGNET`), `ubuntu`,
`remove-probe`, `palette`, `idle` (does nothing; for measurements).

With `--profile <dir>` the GUI settings live in
`<dir>/qBittorrent/config/gui-preferences.plist`, so test runs never change
the regular settings.

### Measurements

`scripts/measure-idle.sh <app> <profile> [settle] [window] [app args]`
reports the physical footprint after `settle` seconds and CPU ms/s and
interrupt wake-ups/s over `window` seconds (`scripts/rusage.swift`).
`--assume-visible` makes a window started in the background refresh like a
visible one.

## Release build

`xcodebuild -configuration Release` produces a self-contained bundle:
`deploy-qt.py` embeds the core, Qt and the Homebrew libraries, removes
absolute run paths and signs every binary with the build's identity, the
hardened runtime and a secure timestamp; Xcode signs the app the same way.
`codesign --verify --deep --strict` passes and `otool -L` shows no
`/opt/homebrew` reference. `scripts/notarize.sh <app> <keychain-profile>`
notarizes and staples a build signed with a Developer ID Application
certificate (not run here; needs the owner's Apple ID).
