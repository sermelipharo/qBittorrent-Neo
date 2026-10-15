import SwiftUI

/// The feed tree with the sticky "Unread" row, context menus, rename on
/// double-click, delete key and drag-and-drop moves into folders.
struct RSSFeedList: View {
    @Bindable var model: RSSModel

    var body: some View {
        List(model.nodes, children: \.children, selection: $model.selection) { node in
            RSSNodeRow(node: node)
                .draggable(node.kind == .unread ? "" : node.id)
                .dropDestination(for: String.self) { ids, _ in
                    guard node.kind == .folder else { return false }
                    Task { await model.move(ids.filter { !$0.isEmpty }, into: node.path) }
                    return true
                }
        }
        .contextMenu(forSelectionType: RSSNode.ID.self) { ids in
            RSSFeedContextMenu(model: model, nodes: ids.compactMap(model.node))
        } primaryAction: { ids in
            if ids.count == 1, let node = ids.first.flatMap(model.node), node.kind != .unread {
                model.sheet = .rename(node)
            }
        }
        .onDeleteCommand {
            let nodes = model.selectedNodes.filter { $0.kind != .unread }
            if !nodes.isEmpty { model.pendingDeletion = nodes }
        }
        .dropDestination(for: String.self) { ids, _ in
            Task { await model.move(ids.filter { !$0.isEmpty }, into: "") }
            return true
        }
        .navigationTitle("RSS feeds")
    }
}
