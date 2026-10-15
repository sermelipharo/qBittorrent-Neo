#if DEBUG
import AppKit

/// Runtime verification aids for debug builds, driven by environment
/// variables so a scripted run can exercise the real app:
/// Whenever one of these runs, windows stay at the normal level but are kept
/// practically invisible (alpha 0.01) and click-through so the user's work is
/// never covered; they become opaque only while the file `capture-on` exists
/// in `QBT_UI_DIR` (an external script creates it around a window capture).
/// Refreshing is forced on, so it does not depend on window occlusion.
/// * `QBT_VERIFY_SEARCH=1`: open the Search window shortly after launch.
/// * `QBT_VERIFY_OPTIONS=1`: open Torrent Options for the loaded torrents;
///   `=disable`: switch DHT, PeX and LSD off for them instead.
/// * `QBT_VERIFY_ACCEPT_ADD=1`: press "Add" in "Add new torrent" dialogs as
///   soon as their metadata is ready.
/// * `QBT_VERIFY_WINDOWS=rss,search,settings,...`: open these windows
///   (`AppWindowID` raw values, or `settings`) one after another, 8 s apart.
/// * `QBT_VERIFY_TABS=<seconds>`: select the first torrent and show each
///   properties tab in turn for that many seconds.
@MainActor
enum DebugVerification {
    static func install(model: AppModel) -> Timer? {
        Symbol.verifyAll()
        let environment = ProcessInfo.processInfo.environment
        if environment["QBT_VERIFY_SEARCH"] == "1" {
            Task {
                try? await Task.sleep(for: .seconds(6))
                model.openWindow?(id: AppWindowID.search.rawValue)
            }
        }
        if let windows = environment["QBT_VERIFY_WINDOWS"] {
            Task { await openWindows(windows.split(separator: ",").map(String.init), model: model) }
        }
        if environment["QBT_VERIFY_ACCEPT_ADD"] == "1" {
            Task { await acceptAddDialogs(model: model) }
        }
        if let seconds = environment["QBT_VERIFY_TABS"].flatMap(Int.init) {
            Task { await cycleTabs(model: model, seconds: seconds) }
        }
        if let mode = environment["QBT_VERIFY_OPTIONS"] {
            Task { await runOptions(mode: mode, model: model) }
        }
        let verifying = environment.keys.contains { $0.hasPrefix("QBT_VERIFY_") }
        guard verifying else { return nil }
        let captureFlag = (environment["QBT_UI_DIR"] ?? NSTemporaryDirectory()) + "/capture-on"
        return Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            MainActor.assumeIsolated {
                let alpha: CGFloat = FileManager.default.fileExists(atPath: captureFlag) ? 1 : 0.01
                for window in NSApp.windows where window.isVisible {
                    if window.alphaValue != alpha { window.alphaValue = alpha }
                    if !window.ignoresMouseEvents { window.ignoresMouseEvents = true }
                }
                if model.mainWindow?.isVisible == true { model.isMainWindowVisible = true }
            }
        }
    }

    private static func openWindows(_ ids: [String], model: AppModel) async {
        try? await Task.sleep(for: .seconds(6))
        for id in ids {
            if id == "settings" {
                // The app menu's "Settings…" item (Command-,).
                if let appMenu = NSApp.mainMenu?.items.first?.submenu,
                   let index = appMenu.items.firstIndex(where: { $0.keyEquivalent == "," }) {
                    appMenu.performActionForItem(at: index)
                }
            } else {
                model.openWindow?(id: id)
            }
            try? await Task.sleep(for: .seconds(8))
        }
    }

    private static func acceptAddDialogs(model: AppModel) async {
        while true {
            try? await Task.sleep(for: .seconds(1))
            for (id, dialog) in model.addDialogs where dialog.phase == .ready {
                let title = dialog.title
                model.accept(id)
                NSApp.windows.first { $0.title == title }?.close()
            }
        }
    }

    private static func cycleTabs(model: AppModel, seconds: Int) async {
        while model.transfers.items.isEmpty { try? await Task.sleep(for: .seconds(1)) }
        model.list.selection = [model.transfers.items[0].id]
        model.gui.propertiesVisible = true
        while true {
            for tab in PropertiesTab.allCases {
                model.gui.propertiesTab = tab
                model.refreshSoon()
                try? await Task.sleep(for: .seconds(seconds))
            }
        }
    }

    private static func runOptions(mode: String, model: AppModel) async {
        while model.transfers.items.isEmpty { try? await Task.sleep(for: .seconds(1)) }
        try? await Task.sleep(for: .seconds(3))
        let ids = model.transfers.items.map(\.id)
        model.list.selection = Set(ids)
        if mode == "disable", let client = model.client {
            // The calls the Torrent Options switches make on OK.
            try? client.setDhtDisabled(hashes: ids, value: true)
            try? client.setPexDisabled(hashes: ids, value: true)
            try? client.setLsdDisabled(hashes: ids, value: true)
        } else {
            model.sheet = .torrentOptions(ids: ids)
        }
    }
}
#endif
