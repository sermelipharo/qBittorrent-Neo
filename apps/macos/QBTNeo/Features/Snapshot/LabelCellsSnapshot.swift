import SwiftUI

/// The transfer list's Category and Tags cells of some demo torrents (those
/// columns are hidden by default, so the table snapshot doesn't show them).
struct LabelCellsSnapshot: View {
    let model: AppModel

    var body: some View {
        let items = model.transfers.items.filter { !$0.category.isEmpty || !$0.tags.isEmpty }.prefix(8)
        Grid(alignment: .leading, horizontalSpacing: Design.Spacing.large, verticalSpacing: Design.Spacing.regular) {
            GridRow {
                Text("Category").font(.headline)
                Text("Tags").font(.headline)
            }
            ForEach(Array(items), id: \.id) { item in
                GridRow {
                    TransferCell(item: item, column: .category, gui: model.gui, labels: model.labels)
                    TransferCell(item: item, column: .tags, gui: model.gui, labels: model.labels)
                }
            }
        }
        .padding(Design.Spacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
