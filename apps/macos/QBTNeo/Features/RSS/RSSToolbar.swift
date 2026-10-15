import SwiftUI

/// RSS toolbar: New subscription, Mark items read, Update all, RSS Downloader.
struct RSSToolbar: ToolbarContent {
    let model: RSSModel
    @Environment(\.openWindow) private var openWindow

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button("New subscription", systemImage: "plus") {
                model.sheet = .newSubscription(url: RSSFeedSheet.clipboardURL())
            }
            .help("New subscription")
            Button("Mark items read", systemImage: "checkmark.circle") { model.markRead(model.selectedNodes) }
                .help("Mark items read")
                .disabled(model.selection.isEmpty)
            Button("Update all", systemImage: "arrow.clockwise", action: model.updateAll)
                .help("Refresh RSS streams")
        }
        ToolbarItem(placement: .primaryAction) {
            Button("RSS Downloader…", systemImage: "arrow.down.doc") {
                openWindow(id: FeatureWindowID.rssDownloader.rawValue)
            }
            .help("RSS Downloader…")
        }
    }
}
