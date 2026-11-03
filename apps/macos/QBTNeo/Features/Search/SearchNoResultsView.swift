import SwiftUI

/// A finished tab without results whose engines reported errors: the status
/// and what the engines said, so an empty tab is explained.
struct SearchNoResultsView: View {
    let tab: SearchTabModel

    var body: some View {
        ContentUnavailableView {
            Label(tab.status.text, systemImage: tab.status.symbol)
        } description: {
            Text("Some search engines reported errors:")
            Text(tab.engineWarnings.joined(separator: "\n"))
                .lineLimit(4)
                .truncationMode(.tail)
                .help(tab.engineWarnings.joined(separator: "\n"))
        }
    }
}
