import SwiftUI

/// Name cell of content trees: indentation, disclosure, checkbox, Finder
/// icon and name.
struct FileNameCell: View {
    let node: FileNode
    let tree: FileTreeModel
    let onToggleCheck: (FileNode) -> Void

    var body: some View {
        HStack(spacing: Design.Spacing.tight) {
            Button {
                tree.toggleExpanded(node)
            } label: {
                Image(systemName: Symbol.chevronRight)
                    .font(.caption.bold())
                    .rotationEffect(.degrees(node.isExpanded || !tree.filterText.isEmpty ? 90 : 0))
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
            }
            .buttonStyle(.plain)
            .opacity(node.isFolder ? 1 : 0)
            .disabled(!node.isFolder)
            .accessibilityLabel(Text(node.isExpanded ? "Collapse" : "Expand"))
            Button {
                onToggleCheck(node)
            } label: {
                Image(systemName: checkSymbol)
                    .foregroundStyle(node.checkState == .unchecked ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(node.checkState == .unchecked ? "Download" : "Do not download"))
            Image(nsImage: node.isFolder ? FileIconCache.folder : FileIconCache.icon(forExtension: (node.name as NSString).pathExtension))
                .resizable()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
            Text(node.name)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(node.priority == .ignored ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .help(node.path)
        }
        .padding(.leading, Double(node.depth) * 16)
    }

    private var checkSymbol: String {
        switch node.checkState {
        case .checked: Symbol.checkmarkSquareFill
        case .unchecked: Symbol.square
        case .partial: Symbol.minusSquareFill
        }
    }
}
