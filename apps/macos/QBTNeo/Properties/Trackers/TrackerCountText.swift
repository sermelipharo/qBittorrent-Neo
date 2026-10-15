import SwiftUI

/// Tracker table text; aggregated values are blanked on expanded trackers
/// (the endpoint rows show them) and sticky rows are grey.
struct TrackerCountText: View {
    let row: TrackerRow
    let text: String
    // Passed in rather than read from the environment: table cells can be
    // built outside the window's environment (accessibility hit tests).
    let properties: PropertiesModel

    var body: some View {
        let blanked = row.kind == .tracker && properties.expandedTrackers.contains(row.url)
        Text(blanked ? "" : text)
            .monospacedDigit()
            .lineLimit(1)
            .foregroundStyle(row.kind == .sticky ? AnyShapeStyle(.secondary) : AnyShapeStyle(statusStyle))
            .help(text)
    }

    private var statusStyle: AnyShapeStyle {
        switch row.status {
        case .trackerError, .notWorking, .unreachable: AnyShapeStyle(TorrentState.error.color)
        default: AnyShapeStyle(.primary)
        }
    }
}
