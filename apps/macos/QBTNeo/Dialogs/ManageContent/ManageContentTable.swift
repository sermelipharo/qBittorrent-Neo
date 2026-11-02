import SwiftUI

/// The file table of the Manage Torrent Content dialog: Index and Path
/// (editable in place), in file order, multiple selection.
struct ManageContentTable: View {
    let dialog: ManageContentModel
    @SceneStorage("ManageContentColumns") private var columns = TableColumnCustomization<ManageContentRow>()

    var body: some View {
        Table(of: ManageContentRow.self, selection: selection, columnCustomization: $columns) {
            TableColumn("Index") { row in
                Text(String(row.id)).monospacedDigit()
            }
            .width(min: 36, ideal: 52).alignment(.trailing).customizationID("index")
            TableColumn("Path") { row in
                ManageContentPathField(row: row) { dialog.setPath($0, forFile: row.id) }
            }
            .width(min: 160, ideal: 560).customizationID("path")
            .disabledCustomizationBehavior(.visibility)
        } rows: {
            ForEach(dialog.rows) { row in
                TableRow(row)
            }
        }
        .accessibilityLabel("Manage Torrent Content")
    }

    private var selection: Binding<Set<Int64>> {
        Binding(get: { dialog.selection }, set: { dialog.select($0) })
    }
}
