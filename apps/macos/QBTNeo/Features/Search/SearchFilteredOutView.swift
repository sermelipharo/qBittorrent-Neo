import SwiftUI

/// Every result of a tab is hidden: says which filter hides them and offers
/// to lift it ("Torrent names only" also hides plugin error rows).
struct SearchFilteredOutView: View {
    @Bindable var tab: SearchTabModel

    var body: some View {
        ContentUnavailableView {
            Label("No results match the filters", systemImage: Symbol.line3HorizontalDecreaseCircle)
        } description: {
            Text("Results hidden by the filters: \(tab.rows.count)")
            if tab.namesOnly {
                Text("\u{201C}Torrent names only\u{201D} hides results whose names don't contain every word you searched for.")
            }
        } actions: {
            if tab.namesOnly {
                Button("Search Everywhere") { tab.namesOnly = false }
            }
            if tab.hasNarrowingFilters {
                Button("Reset Filters", action: tab.resetFilters)
            }
        }
    }
}
