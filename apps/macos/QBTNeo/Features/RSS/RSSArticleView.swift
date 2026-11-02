import SwiftUI

/// Article preview: a header (title, date, feed, author, link) and the
/// sanitized description. Magnet and `.torrent` links add the torrent
/// (qBittorrent 5.3); other links open only http(s) URLs in the browser.
struct RSSArticleView: View {
    let item: RSSArticleItem?
    let showsFeed: Bool
    let download: () -> Void
    let addTorrent: (URL) -> Void
    @State private var description = AttributedString()

    var body: some View {
        if let item {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                    RSSArticleHeader(item: item, showsFeed: showsFeed, download: download)
                    Text(description)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Design.Spacing.large)
            }
            .environment(\.openURL, OpenURLAction { url in
                if RSSLinkPolicy.isTorrentLink(url) {
                    addTorrent(url)
                    return .handled
                }
                return RSSLinkPolicy.isWebURL(url) ? .systemAction : .discarded
            })
            .task(id: item.id) {
                description = RSSDescriptionRenderer.render(item.article.description, link: item.article.link)
            }
        } else {
            ContentUnavailableView("No Article Selected", systemImage: Symbol.docRichtext)
        }
    }
}
