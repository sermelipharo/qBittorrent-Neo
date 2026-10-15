import SwiftUI

/// "Torrent information": size with free space, date, hashes, comment.
struct AddTorrentInfoPanel: View {
    let dialog: AddTorrentModel

    var body: some View {
        let metadata = dialog.metadata
        Grid(alignment: .leading, horizontalSpacing: Design.Spacing.regular, verticalSpacing: Design.Spacing.tight) {
            GridRow {
                PropertyValueRow(label: "Size:", value: dialog.sizeDescription)
            }
            GridRow {
                PropertyValueRow(label: "Date:", value: metadata.map { ValueFormatter.date($0.creationDate) } ?? String(localized: "Not available"))
            }
            GridRow {
                PropertyValueRow(label: "Info hash v1:", value: ValueFormatter.hash(metadata?.infohashV1 ?? ""))
            }
            GridRow {
                PropertyValueRow(label: "Info hash v2:", value: ValueFormatter.hash(metadata?.infohashV2 ?? ""))
            }
            GridRow(alignment: .top) {
                Text("Comment:")
                    .foregroundStyle(.secondary)
                Text(metadata.map { LinkedText.attributed($0.comment) } ?? AttributedString(String(localized: "Not available")))
                    .textSelection(.enabled)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.callout)
    }
}
