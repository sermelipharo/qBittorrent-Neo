import SwiftUI

/// "Information" group (features.md §2.3.3).
struct InformationGroupGrid: View {
    let values: TorrentProperties

    var body: some View {
        let v = values
        let metadata = v.hasMetadata
        Grid(alignment: .leading, horizontalSpacing: Design.Spacing.regular, verticalSpacing: Design.Spacing.tight) {
            GridRow {
                PropertyValueRow(label: "Total Size:", value: metadata ? UnitFormatter.size(v.totalSize) : "")
                PropertyValueRow(label: "Pieces:", value: metadata
                    ? String(localized: "\(v.piecesNum) x \(UnitFormatter.size(v.pieceSize)) (have \(v.piecesHave))") : "")
                PropertyValueRow(label: "Created By:", value: metadata ? v.createdBy : "")
            }
            GridRow {
                PropertyValueRow(label: "Added On:", value: ValueFormatter.date(v.additionDate))
                PropertyValueRow(label: "Completed On:", value: ValueFormatter.date(v.completionDate))
                PropertyValueRow(label: "Created On:", value: metadata ? ValueFormatter.date(v.creationDate) : "")
            }
            GridRow {
                PropertyValueRow(label: "Private:", value: metadata ? ValueFormatter.yesNo(v.private) : String(localized: "N/A"),
                                 valueColumns: 5)
            }
            GridRow {
                PropertyValueRow(label: "Info Hash v1:", value: ValueFormatter.hash(v.infohashV1), valueColumns: 5)
            }
            GridRow {
                PropertyValueRow(label: "Info Hash v2:", value: ValueFormatter.hash(v.infohashV2), valueColumns: 5)
            }
            GridRow {
                PropertyValueRow(label: "Save Path:", value: v.savePath, valueColumns: 5)
            }
            GridRow(alignment: .top) {
                Text("Comment:")
                    .foregroundStyle(.secondary)
                Text(LinkedText.attributed(v.comment))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .gridCellColumns(5)
            }
        }
    }
}
