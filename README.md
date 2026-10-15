# qBittorrent Neo

qBittorrent 5.2.4 with a native SwiftUI interface for macOS. The C++ core
(libtorrent session, preferences, RSS, search, torrent creator, WebUI,
watched folders, logging) is qBittorrent's own code, linked **in-process**
into the app through a small C bridge; there is no HTTP/WebAPI hop and no
separate daemon.

* `qbittorrent/` — upstream qBittorrent 5.2.4 (unmodified, git subtree).
* `core/` — CMake project: qBittorrent's `src/base` + `src/webui` built with
  `GUI=OFF`, plus the bridge library `libqbtneocore.dylib` (C API in
  `core/include/qbtneo.h`).
* `apps/macos/` — XcodeGen project of the SwiftUI app ("qBittorrent Neo",
  `mk.lex.qbittorrentneo`).
* `docs/ARCHITECTURE.md` — how the bridge works; `docs/PARITY.md` — what is
  covered; `docs/SECURITY.md` — security review of the network-facing parts.

## Build

Requirements: Xcode 27 (macOS 27 SDK), Homebrew `qt` (6.x), `boost`,
`openssl@3`, `cmake`, `xcodegen`, `swiftlint`.

```sh
scripts/build-deps.sh        # libtorrent 2.0 (static) into build/deps, once
scripts/build-core.sh        # qBittorrent core + bridge -> build/core/libqbtneocore.dylib
cd apps/macos && xcodegen generate && cd ../..
xcodebuild -project apps/macos/QBTNeo.xcodeproj -scheme QBTNeo -jobs 4 \
    -derivedDataPath build/DerivedData build
```

The Xcode target runs `scripts/build-core.sh` before compiling and
`scripts/deploy-qt.py` after linking (embeds the core, the Qt frameworks,
their Homebrew dependencies and the needed Qt plug-ins, and signs them).

Run with a separate profile: `open -n "qBittorrent Neo.app" --args --profile <dir>`.

## License

GPL-3.0-or-later for the combined application; qBittorrent's sources keep
their GPL-2.0-or-later license. See `NOTICE` and `COPYING`.
