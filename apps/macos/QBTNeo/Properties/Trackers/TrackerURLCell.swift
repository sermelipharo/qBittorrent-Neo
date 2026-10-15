import SwiftUI

/// URL cell: disclosure button for trackers with endpoints, indented
/// endpoint rows, grey sticky rows.
struct TrackerURLCell: View {
    let row: TrackerRow
    // Passed in rather than read from the environment: table cells can be
    // built outside the window's environment (accessibility hit tests).
    let properties: PropertiesModel

    var body: some View {
        let expanded = properties.expandedTrackers.contains(row.url)
        HStack(spacing: Design.Spacing.tight) {
            Button {
                properties.toggleTrackerExpansion(row.url)
            } label: {
                Image(systemName: Symbol.chevronRight)
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
            }
            .buttonStyle(.plain)
            .opacity(row.hasEndpoints ? 1 : 0)
            .disabled(!row.hasEndpoints)
            .accessibilityLabel(Text(expanded ? "Collapse" : "Expand"))
            .padding(.leading, row.kind == .tracker || row.kind == .sticky ? 0 : 16)
            Text(row.url)
                .foregroundStyle(row.kind == .sticky ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .lineLimit(1)
                .truncationMode(.middle)
                .help(row.url)
        }
    }
}
