import SwiftUI

/// A Settings search result: the setting with "Pane › Section" underneath.
struct SettingsSearchRow: View {
    let result: SettingsSearch.Result
    let open: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: open) {
            HStack(spacing: Design.Spacing.medium) {
                Image(systemName: result.spec.pane.symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: Design.Spacing.xLarge)
                VStack(alignment: .leading, spacing: 1) {
                    Text(result.title)
                        .lineLimit(2)
                    Text(result.path)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if result.spec.needsAdvanced {
                    Text("Advanced")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, Design.Spacing.regular)
            .padding(.vertical, Design.Spacing.small)
            .contentShape(.rect)
            .background(isHovered ? AnyShapeStyle(.quaternary) : AnyShapeStyle(.clear), in: .rect(cornerRadius: Design.Radius.medium))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityHint(Text(result.path))
    }
}
