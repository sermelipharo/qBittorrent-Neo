import SwiftUI

/// "Select All / Select None" buttons and the "Filter files..." field with
/// its pattern-format menu, above a content tree.
struct FileTreeFilterBar: View {
    @Bindable var tree: FileTreeModel
    let onSelectAll: () -> Void
    let onSelectNone: () -> Void

    var body: some View {
        HStack(spacing: Design.Spacing.regular) {
            Button("Select All", action: onSelectAll)
            Button("Select None", action: onSelectNone)
            Spacer()
            HStack(spacing: Design.Spacing.tight) {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Filter files…", text: $tree.filterText)
                    .textFieldStyle(.plain)
                Menu("Pattern Format", systemImage: "ellipsis.circle") {
                    Picker("Pattern Format", selection: $tree.patternFormat) {
                        ForEach(FilterPatternFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .labelStyle(.iconOnly)
                .fixedSize()
            }
            .padding(.horizontal, Design.Spacing.small)
            .padding(.vertical, Design.Spacing.hairline + 1)
            .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: Design.Radius.medium))
            .frame(maxWidth: 300)
        }
        .controlSize(.small)
    }
}
