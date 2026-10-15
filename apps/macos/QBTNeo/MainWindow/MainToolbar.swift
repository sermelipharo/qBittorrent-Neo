import SwiftUI

/// Main window toolbar (features.md §1.2): add, remove, start/stop, queue
/// (when queueing is enabled) and options; the filter field is `.searchable`.
struct MainToolbar: ToolbarContent {
    let model: AppModel
    let openSettings: OpenSettingsAction

    var body: some ToolbarContent {
        let ids = model.list.selectedIDs
        ToolbarItemGroup(placement: .navigation) {
            Button("Add Torrent File", systemImage: Symbol.docBadgePlus) { model.fileImport = .torrentFiles }
                .help("Add Torrent File… (⌘O)")
            Button("Add Torrent Link", systemImage: Symbol.linkBadgePlus) {
                model.sheet = .addLinks(initialText: AppModel.clipboardLinks())
            }
            .help("Add Torrent Link… (⇧⌘O)")
        }
        ToolbarItemGroup {
            Button("Remove", systemImage: Symbol.trash) { model.requestRemove(ids) }
                .disabled(ids.isEmpty)
                .help("Remove the selected torrents (⌘⌫)")
        }
        ToolbarItemGroup {
            Button("Start", systemImage: Symbol.playFill) { model.start(ids) }
                .disabled(ids.isEmpty)
                .help("Start the selected torrents (⌘S)")
            Button("Stop", systemImage: Symbol.pauseFill) { model.stop(ids) }
                .disabled(ids.isEmpty)
                .help("Stop the selected torrents (⌘P)")
        }
        if model.queueingEnabled {
            ToolbarItemGroup {
                Button("Top of Queue", systemImage: Symbol.arrowUpToLine) { model.queue(ids, .top) }
                    .help("Move to the top of the queue")
                    .disabled(ids.isEmpty)
                Button("Move Up Queue", systemImage: Symbol.chevronUp) { model.queue(ids, .up) }
                    .help("Move up in the queue")
                    .disabled(ids.isEmpty)
                Button("Move Down Queue", systemImage: Symbol.chevronDown) { model.queue(ids, .down) }
                    .help("Move down in the queue")
                    .disabled(ids.isEmpty)
                Button("Bottom of Queue", systemImage: Symbol.arrowDownToLine) { model.queue(ids, .bottom) }
                    .help("Move to the bottom of the queue")
                    .disabled(ids.isEmpty)
            }
        }
        ToolbarItem {
            Button("Lock", systemImage: Symbol.lock) { model.requestLock() }
                .help("Lock qBittorrent Neo (⌘L)")
        }
        ToolbarItem {
            Button("Options", systemImage: Symbol.gearshape) { openSettings() }
                .help("Options… (⌥O)")
        }
    }
}
