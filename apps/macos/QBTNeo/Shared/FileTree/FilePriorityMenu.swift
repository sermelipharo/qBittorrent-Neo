import SwiftUI

/// Priority cell: a borderless menu showing the current priority
/// ("Mixed" for folders whose children differ).
struct FilePriorityMenu: View {
    let node: FileNode
    let onSelect: (FilePriorityChoice) -> Void

    var body: some View {
        Menu(node.priority.title) {
            ForEach(FilePriorityChoice.selectable) { choice in
                Button(choice.title) { onSelect(choice) }
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.visible)
        .fixedSize()
        .foregroundStyle(node.priority == .ignored ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
        .accessibilityLabel(Text("Download priority: \(node.priority.title)"))
    }
}
