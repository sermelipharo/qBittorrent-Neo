import Foundation

/// An article with the feed it belongs to (needed to mark it read).
struct RSSArticleItem: Identifiable, Hashable {
    let id: String
    let feedPath: String
    let feedTitle: String
    var article: RssArticle

    init(article: RssArticle, feed: RssFeed) {
        id = feed.path + "\u{1}" + article.id
        feedPath = feed.path
        feedTitle = feed.title.isEmpty ? feed.path : feed.title
        self.article = article
    }
}
