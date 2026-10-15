import SwiftUI

/// Content tab context menu (features.md §2.7.3).
struct ContentContextMenu: View {
    let item: TorrentItem
    let nodes: [FileNode]
    let apply: ([FilePriority: [Int64]]) -> Void
    @Environment(AppModel.self) private var model

    var body: some View {
        let tree = model.properties.files
        if nodes.count == 1, let node = nodes.first {
            Button("Open", systemImage: Symbol.arrowUpForwardApp) { model.openContent(item, node) }
            Button("Open Containing Folder", systemImage: Symbol.folder) { model.revealContent(item, node) }
            Button("Rename…", systemImage: Symbol.pencil) { model.requestRenameContent(item, node) }
            Divider()
            Menu("Priority") {
                ForEach(FilePriorityChoice.selectable) { choice in
                    Button(choice.title) { apply(tree.setPriority(choice, for: nodes)) }
                }
                Divider()
                Button("By Shown File Order") { apply(tree.prioritizeByShownOrder(nodes)) }
            }
        } else if nodes.count > 1 {
            ForEach(FilePriorityChoice.selectable) { choice in
                Button(choice.menuTitle) { apply(tree.setPriority(choice, for: nodes)) }
            }
            Divider()
            Button("Priority by Shown File Order") { apply(tree.prioritizeByShownOrder(nodes)) }
        }
    }
}
