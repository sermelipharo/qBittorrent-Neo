import SwiftUI

/// A search tab: status icon, pattern, result count and a close button.
struct SearchTabChip: View {
    let tab: SearchTabModel
    let isCurrent: Bool
    let select: () -> Void
    let close: () -> Void

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            Button(action: select) {
                HStack(spacing: Design.Spacing.small) {
                    if tab.status == .ongoing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: tab.status.symbol)
                            .foregroundStyle(.secondary)
                    }
                    Text(tab.pattern)
                        .lineLimit(1)
                    Text(tab.rows.count.formatted())
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .help(tab.status.text)
            Button("Close tab", systemImage: "xmark", action: close)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Design.Spacing.regular)
        .padding(.vertical, Design.Spacing.tight)
        .background(isCurrent ? AnyShapeStyle(.selection.opacity(0.35)) : AnyShapeStyle(.quaternary.opacity(0.6)), in: .capsule)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }
}
