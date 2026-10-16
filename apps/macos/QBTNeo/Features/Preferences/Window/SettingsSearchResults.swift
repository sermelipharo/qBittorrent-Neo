import SwiftUI

/// Search results shown in place of the pane while the toolbar field has
/// text: "Setting" with "Pane › Section" underneath. Choosing one opens its
/// pane, reveals its tier and highlights it.
struct SettingsSearchResults: View {
    let query: String
    let open: (SettingsSearch.Result) -> Void
    @State private var contentHeight = 200.0

    var body: some View {
        let results = SettingsSearch.search(query)
        Group {
            if results.isEmpty {
                ContentUnavailableView.search(text: query)
                    .frame(height: 200)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(results) { result in
                            SettingsSearchRow(result: result) { open(result) }
                        }
                    }
                    .padding(SettingsLayout.margin / 2)
                    .frame(maxWidth: SettingsLayout.searchResultsWidth)
                    .frame(maxWidth: .infinity)
                    .onGeometryChange(for: Double.self) { $0.size.height } action: { contentHeight = $0 }
                }
                .frame(height: min(max(contentHeight, SettingsLayout.minPaneHeight), SettingsLayout.maxPaneHeight))
            }
        }
        .frame(width: SettingsLayout.windowWidth)
    }
}
