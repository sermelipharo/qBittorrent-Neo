import SwiftUI

/// Content tab (features.md §2.7): file tree with progress, priorities,
/// availability, filter, Select All / None and the file context menu.
struct ContentTab: View {
    let item: TorrentItem
    @Environment(AppModel.self) private var model
    @SceneStorage("ContentListColumns") private var columns = TableColumnCustomization<FileNode>()

    var body: some View {
        @Bindable var tree = model.properties.files
        VStack(spacing: 0) {
            FileTreeFilterBar(tree: tree, onSelectAll: { apply(tree.setAllChecked(true)) },
                              onSelectNone: { apply(tree.setAllChecked(false)) })
                .padding(.horizontal, Design.Spacing.medium)
                .padding(.vertical, Design.Spacing.small)
            Divider()
            Table(of: FileNode.self, selection: $tree.selection, sortOrder: $tree.sortOrder, columnCustomization: $columns) {
                TableColumn("Name", sortUsing: FileSort(.name)) { node in
                    FileNameCell(node: node, tree: tree) { apply(tree.toggleChecked([$0])) }
                }
                .width(min: 160, ideal: 360)
                .customizationID("name")
                .disabledCustomizationBehavior(.visibility)
                TableColumn("Total Size", sortUsing: FileSort(.size)) { node in
                    Text(UnitFormatter.size(node.size)).monospacedDigit()
                }
                .width(min: 60, ideal: 90).alignment(.trailing).customizationID("size")
                TableColumn("Progress", sortUsing: FileSort(.progress)) { node in
                    ProgressBarView(progress: node.size == 0 ? 1 : node.progress, isDimmed: node.priority == .ignored)
                }
                .width(min: 60, ideal: 110).customizationID("progress")
                TableColumn("Download Priority", sortUsing: FileSort(.priority)) { node in
                    FilePriorityMenu(node: node) { apply(tree.setPriority($0, for: [node])) }
                }
                .width(min: 80, ideal: 130).customizationID("priority")
                TableColumn("Remaining", sortUsing: FileSort(.remaining)) { node in
                    Text(UnitFormatter.size(node.remaining)).monospacedDigit()
                }
                .width(min: 60, ideal: 90).alignment(.trailing).customizationID("remaining")
                TableColumn("Availability", sortUsing: FileSort(.availability)) { node in
                    Text(node.availability < 0 ? String(localized: "N/A") : ValueFormatter.progress(node.availability))
                        .monospacedDigit()
                }
                .width(min: 60, ideal: 90).alignment(.trailing).customizationID("availability")
            } rows: {
                ForEach(tree.rows) { node in
                    TableRow(node)
                }
            }
            .contextMenu(forSelectionType: String.self) { ids in
                ContentContextMenu(item: item, nodes: tree.rows.filter { ids.contains($0.id) }, apply: apply)
            } primaryAction: { ids in
                if ids.count == 1, let node = tree.rows.first(where: { ids.contains($0.id) }) {
                    model.openContent(item, node)
                }
            }
            .onKeyPress(.space) {
                apply(tree.toggleChecked(tree.selectedNodes))
                return .handled
            }
            .onKeyPress(.rightArrow) {
                tree.setExpanded(true, for: tree.selectedNodes)
                return .handled
            }
            .onKeyPress(.leftArrow) {
                tree.setExpanded(false, for: tree.selectedNodes)
                return .handled
            }
            .overlay {
                if tree.isEmpty {
                    if !item.hasMetadata {
                        ContentUnavailableView("Waiting for Metadata", systemImage: Symbol.arrowDownCircleDotted,
                                               description: Text("The file list appears once metadata has been received."))
                    } else {
                        PropertiesFailureOverlay(tab: .content, isEmpty: true)
                    }
                }
            }
        }
    }

    private func apply(_ changes: [FilePriority: [Int64]]) {
        model.applyFilePriorities(item.id, changes)
    }
}
