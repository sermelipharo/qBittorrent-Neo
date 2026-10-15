import SwiftUI

/// Content tree of the Add Torrent dialog: Name, Total Size, Priority;
/// double-click renames; Space toggles; filter and Select All / None.
struct AddTorrentContentTree: View {
    let dialog: AddTorrentModel
    @State private var renaming: FileNode?
    @State private var newName = ""
    @State private var renameError: String?

    var body: some View {
        @Bindable var tree = dialog.tree
        VStack(spacing: 0) {
            FileTreeFilterBar(tree: tree, onSelectAll: { tree.setAllChecked(true) }, onSelectNone: { tree.setAllChecked(false) })
                .padding(.horizontal, Design.Spacing.medium)
                .padding(.vertical, Design.Spacing.small)
                .disabled(!dialog.hasMetadata)
            Table(of: FileNode.self, selection: $tree.selection, sortOrder: $tree.sortOrder) {
                TableColumn("Name", sortUsing: FileSort(.name)) { node in
                    FileNameCell(node: node, tree: tree) { tree.toggleChecked([$0]) }
                }
                .width(min: 200, ideal: 340)
                TableColumn("Total Size", sortUsing: FileSort(.size)) { node in
                    Text(UnitFormatter.size(node.size)).monospacedDigit()
                }
                .width(min: 60, ideal: 90)
                .alignment(.trailing)
                TableColumn("Download Priority", sortUsing: FileSort(.priority)) { node in
                    FilePriorityMenu(node: node) { tree.setPriority($0, for: [node]) }
                }
                .width(min: 90, ideal: 130)
            } rows: {
                ForEach(tree.rows) { node in
                    TableRow(node)
                }
            }
            .contextMenu(forSelectionType: String.self) { ids in
                let nodes = tree.rows.filter { ids.contains($0.id) }
                if nodes.count == 1, let node = nodes.first {
                    Button("Rename…", systemImage: Symbol.pencil) { beginRename(node) }
                    Divider()
                }
                ForEach(FilePriorityChoice.selectable) { choice in
                    Button(nodes.count == 1 ? choice.title : choice.menuTitle) { tree.setPriority(choice, for: nodes) }
                }
                Divider()
                Button("By Shown File Order") { tree.prioritizeByShownOrder(nodes) }
            } primaryAction: { ids in
                if let node = tree.rows.first(where: { ids.contains($0.id) }) { beginRename(node) }
            }
            .onKeyPress(.space) {
                tree.toggleChecked(tree.selectedNodes)
                return .handled
            }
            .overlay {
                if !dialog.hasMetadata {
                    AddTorrentMetadataState(dialog: dialog)
                }
            }
        }
        .alert("Renaming", isPresented: isRenaming) {
            TextField("New name:", text: $newName)
            Button("Rename", action: commitRename)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(renameError ?? String(localized: "New name:"))
        }
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })
    }

    private func beginRename(_ node: FileNode) {
        newName = node.name
        renameError = nil
        renaming = node
    }

    private func commitRename() {
        guard let node = renaming else { return }
        do {
            try dialog.rename(node, to: newName)
        } catch {
            renameError = error.userMessage
        }
    }
}
