import SwiftUI

/// Main window toolbar (features.md §1.2): add, remove, start/stop, queue
/// (when queueing is enabled) and options; the filter field is `.searchable`.
struct MainToolbar: ToolbarContent {
    let model: AppModel
    let openSettings: OpenSettingsAction

    var body: some ToolbarContent {
        let ids = model.list.selectedIDs
        ToolbarItemGroup(placement: .navigation) {
            Button("Add Torrent File", systemImage: "doc.badge.plus") { model.fileImport = .torrentFiles }
                .help("Add Torrent File… (⌘O)")
            Button("Add Torrent Link", systemImage: "link.badge.plus") {
                model.sheet = .addLinks(initialText: AppModel.clipboardLinks())
            }
            .help("Add Torrent Link… (⇧⌘O)")
        }
        ToolbarItemGroup {
            Button("Remove", systemImage: "trash") { model.requestRemove(ids) }
                .disabled(ids.isEmpty)
                .help("Remove the selected torrents (⌘⌫)")
        }
        ToolbarItemGroup {
            Button("Start", systemImage: "play.fill") { model.start(ids) }
                .disabled(ids.isEmpty)
                .help("Start the selected torrents (⌘S)")
            Button("Stop", systemImage: "pause.fill") { model.stop(ids) }
                .disabled(ids.isEmpty)
                .help("Stop the selected torrents (⌘P)")
        }
        if model.queueingEnabled {
            ToolbarItemGroup {
                Button("Top of Queue", systemImage: "arrow.up.to.line") { model.queue(ids, .top) }
                    .help("Move to the top of the queue")
                    .disabled(ids.isEmpty)
                Button("Move Up Queue", systemImage: "chevron.up") { model.queue(ids, .up) }
                    .help("Move up in the queue")
                    .disabled(ids.isEmpty)
                Button("Move Down Queue", systemImage: "chevron.down") { model.queue(ids, .down) }
                    .help("Move down in the queue")
                    .disabled(ids.isEmpty)
                Button("Bottom of Queue", systemImage: "arrow.down.to.line") { model.queue(ids, .bottom) }
                    .help("Move to the bottom of the queue")
                    .disabled(ids.isEmpty)
            }
        }
        ToolbarItem {
            Button("Lock", systemImage: "lock") { model.requestLock() }
                .help("Lock qBittorrent Neo (⌘L)")
        }
        ToolbarItem {
            Button("Options", systemImage: "gearshape") { openSettings() }
                .help("Options… (⌥O)")
        }
    }
}
