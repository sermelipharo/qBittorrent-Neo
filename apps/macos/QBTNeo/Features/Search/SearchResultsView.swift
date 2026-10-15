import SwiftUI

/// Filter row, results table and context menu of one search tab.
struct SearchResultsView: View {
    let model: SearchModel
    @Bindable var tab: SearchTabModel
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 0) {
            SearchFilterBar(tab: tab)
            Table(tab.visibleRows, selection: $tab.selection, sortOrder: $tab.sortOrder) {
                TableColumn("Name", value: \.name) { row in
                    Text(row.name)
                        .foregroundStyle(tab.visited.contains(row.id) ? .secondary : .primary)
                        .help(row.name)
                }
                .width(min: 200, ideal: 420)
                TableColumn("Size", value: \.size) { row in
                    Text(row.sizeText).monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
                }
                .width(min: 60, ideal: 80)
                TableColumn("Seeders", value: \.seeders) { row in
                    Text(row.seeders.formatted()).monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
                }
                .width(min: 50, ideal: 60)
                TableColumn("Leechers", value: \.leechers) { row in
                    Text(row.leechers.formatted()).monospacedDigit().frame(maxWidth: .infinity, alignment: .trailing)
                }
                .width(min: 50, ideal: 60)
                TableColumn("Engine", value: \.engine) { row in Text(row.engine) }
                    .width(min: 70, ideal: 110)
                TableColumn("Engine URL", value: \.engineURL) { row in Text(row.engineURL).foregroundStyle(.secondary) }
                    .width(min: 80, ideal: 160)
                TableColumn("Published On", value: \.published) { row in Text(row.publishedText).monospacedDigit() }
                    .width(min: 90, ideal: 130)
            }
            .contextMenu(forSelectionType: SearchResultRow.ID.self) { ids in
                let rows = tab.rows.filter { ids.contains($0.id) }
                Button("Open download window", systemImage: "arrow.down.doc") {
                    model.download(rows, in: tab, app: app, skipDialog: false)
                }
                Button("Download", systemImage: "arrow.down.circle") { model.download(rows, in: tab, app: app, skipDialog: true) }
                Divider()
                Button("Open description page", systemImage: "safari") { model.openDescriptions(rows, app: app) }
                Menu("Copy") {
                    Button("Name") { model.copy(rows, \.fileName) }
                    Button("Download link") { model.copy(rows, \.fileUrl) }
                    Button("Description page URL") { model.copy(rows, \.descrLink) }
                }
            } primaryAction: { ids in
                model.download(tab.rows.filter { ids.contains($0.id) }, in: tab, app: app, skipDialog: false)
            }
            .overlay {
                if tab.visibleRows.isEmpty, tab.status != .ongoing {
                    ContentUnavailableView(tab.rows.isEmpty ? tab.status.text : String(localized: "No results match the filters"),
                                           systemImage: tab.status.symbol)
                }
            }
        }
    }
}
