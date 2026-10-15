#if DEBUG
import AppKit

/// Runtime verification aids for debug builds, driven by environment
/// variables so a scripted run can exercise the real app:
/// * `QBT_VERIFY_FLOAT=1`: keep every window above other apps (occluded
///   windows stop refreshing, which hides what a screenshot should show).
/// * `QBT_VERIFY_SEARCH=1`: open the Search window shortly after launch.
/// * `QBT_VERIFY_OPTIONS=1`: open Torrent Options for the loaded torrents;
///   `=disable`: switch DHT, PeX and LSD off for them instead.
/// * `QBT_VERIFY_ACCEPT_ADD=1`: press "Add" in "Add new torrent" dialogs as
///   soon as their metadata is ready.
/// * `QBT_VERIFY_TABS=<seconds>`: select the first torrent and show each
///   properties tab in turn for that many seconds.
@MainActor
enum DebugVerification {
    static func install(model: AppModel) -> Timer? {
        let environment = ProcessInfo.processInfo.environment
        if environment["QBT_VERIFY_SEARCH"] == "1" {
            Task {
                try? await Task.sleep(for: .seconds(6))
                model.openWindow?(id: AppWindowID.search.rawValue)
            }
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
        guard environment["QBT_VERIFY_FLOAT"] == "1" else { return nil }
        return Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            MainActor.assumeIsolated {
                for window in NSApp.windows where window.isVisible {
                    window.level = .floating
                    window.orderFrontRegardless()
                }
            }
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
