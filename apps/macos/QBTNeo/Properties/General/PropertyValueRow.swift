import SwiftUI

/// One "Label: value" pair inside a General tab grid row.
struct PropertyValueRow: View {
    let label: LocalizedStringKey
    let value: String
    var help: LocalizedStringKey?
    /// Grid columns the value spans (1 = its own column).
    var valueColumns = 1

    var body: some View {
        Text(label)
            .foregroundStyle(.secondary)
            .gridColumnAlignment(.trailing)
            .help(help.map { Text($0) } ?? Text(""))
        Text(value)
            .monospacedDigit()
            .textSelection(.enabled)
            .lineLimit(1)
            .truncationMode(.middle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gridColumnAlignment(.leading)
            .gridCellColumns(valueColumns)
            .help(value)
    }
}
