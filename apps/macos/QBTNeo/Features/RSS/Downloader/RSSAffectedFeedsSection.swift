import SwiftUI

/// "Apply Rule to Feeds:" checklist (mixed state across several rules).
struct RSSAffectedFeedsSection: View {
    let model: RSSDownloaderModel

    var body: some View {
        Section("Apply Rule to Feeds:") {
            if model.feeds.isEmpty {
                Text("No feeds")
                    .foregroundStyle(.secondary)
            }
            ForEach(model.feeds, id: \.url) { feed in
                FeedCheckRow(name: feed.name, url: feed.url, state: model.feedState(feed.url)) { included in
                    model.setFeed(feed.url, included: included)
                }
            }
        }
    }
}
