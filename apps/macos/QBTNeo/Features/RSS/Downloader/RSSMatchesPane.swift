import SwiftUI

/// "Matching RSS Articles": one section per feed with the matching titles.
struct RSSMatchesPane: View {
    let matches: [RssMatchingArticles]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Matching RSS Articles")
                .font(.headline)
                .padding(Design.Spacing.medium)
            List {
                ForEach(matches, id: \.feedName) { feed in
                    Section {
                        ForEach(feed.articleTitles, id: \.self) { title in
                            Text(title)
                                .lineLimit(2)
                                .help(title)
                        }
                    } header: {
                        Label(feed.feedName, systemImage: Symbol.folder)
                            .bold()
                            .help(feed.feedName)
                    }
                }
            }
            .overlay {
                if matches.isEmpty {
                    ContentUnavailableView("No Matches", systemImage: Symbol.line3HorizontalDecreaseCircle,
                                           description: Text("Articles matched by the selected rules appear here."))
                }
            }
        }
    }
}
