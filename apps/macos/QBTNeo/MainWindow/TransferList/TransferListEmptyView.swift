import SwiftUI

/// Shown when the transfer list has no rows.
struct TransferListEmptyView: View {
    /// True when torrents exist but the filters hide them all.
    let isFiltering: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        if isFiltering {
            ContentUnavailableView {
                Label("No Matching Torrents", systemImage: Symbol.line3HorizontalDecreaseCircle)
            } description: {
                Text("No torrents match the current filters.")
            } actions: {
                Button("Show All Torrents", action: showAll)
            }
        } else {
            ContentUnavailableView {
                Label("No Torrents", systemImage: Symbol.arrowDownCircle)
            } description: {
                Text("Add a .torrent file or a magnet link, or drop them here.")
            } actions: {
                Button("Add Torrent File…") { model.fileImport = .torrentFiles }
                Button("Add Torrent Link…") { model.sheet = .addLinks(initialText: AppModel.clipboardLinks()) }
            }
        }
    }

    private func showAll() {
        model.list.statusFilter = .all
        model.list.resetSidebarFilters()
        model.list.searchText = ""
    }
}
