import SwiftUI

/// Trackers tab context menu (features.md §2.4.4).
struct TrackerContextMenu: View {
    let item: TorrentItem
    let ids: Set<String>
    @Environment(AppModel.self) private var model

    var body: some View {
        let urls = model.trackerURLs(rowIDs: ids)
        let running = !item.state.isStopped
        Button("Add Trackers…", systemImage: Symbol.plus) { model.sheet = .addTrackers(id: item.id) }
        if !urls.isEmpty {
            Button("Edit Tracker URL…", systemImage: Symbol.pencil) { model.requestEditTracker(hash: item.id, rowIDs: ids) }
            Button("Remove Tracker", systemImage: Symbol.minusCircle) {
                model.perform { try $0.removeTrackers(hash: item.id, urls: urls) }
            }
            Button("Copy Tracker URL", systemImage: Symbol.docOnDoc) { model.copyToPasteboard(urls.joined(separator: "\n")) }
            if running {
                Button("Force Reannounce to Selected Trackers", systemImage: Symbol.arrowClockwise) { model.reannounce([item.id]) }
            }
        }
        if running {
            Divider()
            Button("Force Reannounce to All Trackers", systemImage: Symbol.arrowClockwiseCircle) { model.reannounce([item.id]) }
        }
    }
}
