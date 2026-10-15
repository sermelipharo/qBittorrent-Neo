import SwiftUI

/// The boxed header of the article preview.
struct RSSArticleHeader: View {
    let item: RSSArticleItem
    let showsFeed: Bool
    let download: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text(item.article.title)
                .font(.title3)
                .bold()
                .textSelection(.enabled)
            Grid(alignment: .leading, horizontalSpacing: Design.Spacing.regular, verticalSpacing: Design.Spacing.tight) {
                if item.article.date > 0 {
                    GridRow {
                        Text("Date:").bold()
                        Text(ValueFormatter.date(item.article.date))
                    }
                }
                if showsFeed {
                    GridRow {
                        Text("Feed:").bold()
                        Text(item.feedTitle)
                    }
                }
                if !item.article.author.isEmpty {
                    GridRow {
                        Text("Author:").bold()
                        Text(item.article.author)
                    }
                }
            }
            .font(.callout)
            HStack {
                if let link = URL(string: item.article.link), RSSLinkPolicy.isWebURL(link) {
                    Link("Open link", destination: link)
                }
                Spacer()
                if !item.article.torrentUrl.isEmpty {
                    Button("Download torrent", systemImage: "arrow.down.circle", action: download)
                }
            }
        }
        .padding(Design.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: Design.Radius.large))
    }
}
