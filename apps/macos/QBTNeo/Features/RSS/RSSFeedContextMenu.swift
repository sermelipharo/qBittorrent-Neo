import SwiftUI

/// Context menu of the feed tree (features.md §5.12.1).
struct RSSFeedContextMenu: View {
    let model: RSSModel
    let nodes: [RSSNode]

    var body: some View {
        if nodes.isEmpty {
            Button("New subscription…", action: newSubscription)
            Button("New folder…") { model.sheet = .newFolder }
            Divider()
            Button("Update all feeds", action: model.updateAll)
        } else {
            Button("Update") { model.update(nodes) }
            Button("Mark items read") { model.markRead(nodes) }
            Divider()
            if nodes.count == 1, let node = nodes.first, node.kind != .unread {
                Button("Rename…") { model.sheet = .rename(node) }
                if node.kind == .feed {
                    Button("Feed options…") { model.sheet = .feedOptions(node) }
                }
                Button("Delete") { model.pendingDeletion = [node] }
                if node.kind == .folder {
                    Divider()
                    Button("New folder…") { model.sheet = .newFolder }
                }
                Divider()
            } else if nodes.count > 1 {
                Button("Delete") { model.pendingDeletion = nodes.filter { $0.kind != .unread } }
                Divider()
            }
            Button("New subscription…", action: newSubscription)
            if nodes.first?.kind == .feed {
                Divider()
                Button("Copy feed URL") { model.copyFeedURLs(nodes) }
            }
        }
    }

    private func newSubscription() {
        model.sheet = .newSubscription(url: RSSFeedSheet.clipboardURL())
    }
}
