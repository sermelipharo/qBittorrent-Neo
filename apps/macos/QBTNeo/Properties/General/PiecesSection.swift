import SwiftUI

/// Progress (downloaded pieces) and Availability bars with their values.
struct PiecesSection: View {
    let item: TorrentItem
    let values: TorrentProperties
    let pieces: [UInt8]
    let availability: [UInt32]

    var body: some View {
        let showsAvailability = PropertiesModel.showsAvailability(item)
        Grid(alignment: .leading, horizontalSpacing: Design.Spacing.regular, verticalSpacing: Design.Spacing.small) {
            GridRow {
                Text("Progress:")
                    .foregroundStyle(.secondary)
                    .gridColumnAlignment(.trailing)
                PiecesBar(content: .states(item.hasMetadata ? pieces : []))
                    .help("Missing pieces · Partial pieces (green) · Completed pieces (accent)")
                    .accessibilityLabel(Text("Downloaded pieces"))
                Text(item.hasMetadata ? "\((values.progress * 100).formatted(.number.precision(.fractionLength(1)).rounded(rule: .down)))%" : "")
                    .monospacedDigit()
                    .frame(width: 64, alignment: .trailing)
            }
            if showsAvailability {
                GridRow {
                    Text("Availability:")
                        .foregroundStyle(.secondary)
                    PiecesBar(content: .availability(availability))
                        .help("Unavailable pieces · Available pieces")
                        .accessibilityLabel(Text("Piece availability"))
                    Text(values.availability.formatted(.number.precision(.fractionLength(3))))
                        .monospacedDigit()
                        .frame(width: 64, alignment: .trailing)
                }
            }
        }
    }
}
