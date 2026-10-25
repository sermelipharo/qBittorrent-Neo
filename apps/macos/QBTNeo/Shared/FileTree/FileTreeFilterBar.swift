import SwiftUI

/// "Select All / Select None" buttons and the "Filter files..." field with
/// its pattern-format menu, above a content tree.
struct FileTreeFilterBar: View {
    @Bindable var tree: FileTreeModel
    let onSelectAll: () -> Void
    let onSelectNone: () -> Void
    /// Shown first, e.g. how many files there are and what is selected.
    var summary: String?

    var body: some View {
        HStack(spacing: Design.Spacing.regular) {
            if let summary {
                Text(summary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(summary)
            }
            Button("Select All", action: onSelectAll)
            Button("Select None", action: onSelectNone)
            Spacer()
            HStack(spacing: Design.Spacing.tight) {
                Image(systemName: Symbol.line3HorizontalDecrease)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Filter files…", text: $tree.filterText)
                    .textFieldStyle(.plain)
                Menu("Pattern Format", systemImage: Symbol.ellipsisCircle) {
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
            .frame(minWidth: summary == nil ? nil : 140, maxWidth: summary == nil ? 300 : 200)
        }
        .controlSize(.small)
    }
}
