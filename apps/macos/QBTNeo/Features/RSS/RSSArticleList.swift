import SwiftUI

/// Articles of the selected feeds/folders (newest first). Double-click or
/// Return downloads; the context menu offers download and open news URL.
struct RSSArticleList: View {
    @Bindable var model: RSSModel
    @Environment(AppModel.self) private var app
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        List(model.articles, selection: $model.articleSelection) { item in
            RSSArticleRow(item: item, showsFeed: model.showsFeedColumn)
        }
        .contextMenu(forSelectionType: RSSArticleItem.ID.self) { ids in
            let items = model.articles.filter { ids.contains($0.id) }
            if items.contains(where: { !$0.article.torrentUrl.isEmpty }) {
                Button("Download torrent", systemImage: Symbol.arrowDownCircle) { model.download(items, app: app) }
            }
            if items.contains(where: { !$0.article.link.isEmpty }) {
                Button("Open news URL", systemImage: Symbol.safari) { model.openNewsURLs(items, app: app) }
            }
        } primaryAction: { ids in
            model.download(model.articles.filter { ids.contains($0.id) }, app: app)
        }
        .overlay {
            if model.articles.isEmpty {
                ContentUnavailableView(
                    model.filter.isEmpty ? "No Articles" : "No Matches", systemImage: Symbol.newspaper,
                    description: Text(model.filter.isEmpty ? "Select a feed or folder to see its articles." : "No article title matches the filter.")
                )
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 0) {
                if !app.corePreferences.rss.rssProcessingEnabled {
                    FeatureBanner(text: "Fetching of RSS feeds is disabled now! You can enable it in application settings.",
                                  actionTitle: "Settings…") { openSettings() }
                }
                Text("Torrents: (double-click to download)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Design.Spacing.medium)
                    .padding(.vertical, Design.Spacing.small)
            }
            .background(.bar)
        }
    }
}
