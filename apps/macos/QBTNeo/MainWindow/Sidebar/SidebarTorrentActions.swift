import SwiftUI

/// "Start torrents / Stop torrents / Remove torrents" of every sidebar
/// context menu; they act on the torrents currently visible in the list.
struct SidebarTorrentActions: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button("Start Torrents", systemImage: "play.fill") { model.start(model.visibleIDs) }
        Button("Stop Torrents", systemImage: "pause.fill") { model.stop(model.visibleIDs) }
        Button("Remove Torrents", systemImage: "trash") { model.requestRemove(model.visibleIDs) }
    }
}
