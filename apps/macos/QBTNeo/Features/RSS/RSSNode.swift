import Foundation

/// A row of the feed tree: the sticky "Unread" item, a folder or a feed.
struct RSSNode: Identifiable, Hashable {
    enum Kind: Hashable {
        case unread
        case folder
        case feed
    }

    /// Identifier of the sticky "Unread" row (not a valid item path).
    static let unreadID = "\u{1}unread"

    let id: String
    let kind: Kind
    let name: String
    let unreadCount: Int64
    var isLoading = false
    var hasError = false
    var url = ""
    var refreshInterval: Int64 = 0
    var iconPath = ""
    var children: [Self]?

    /// The item path in the core ("" = root for the Unread row).
    var path: String { kind == .unread ? "" : id }

    /// Parent folder path of the item.
    var parentPath: String {
        guard let index = id.lastIndex(of: "\\") else { return "" }
        return String(id[..<index])
    }

    init(folder: RssFolder) {
        id = folder.path
        kind = .folder
        name = folder.name
        let feeds = folder.feeds.map(Self.init(feed:))
        let folders = folder.folders.map(Self.init(folder:))
        unreadCount = feeds.reduce(0) { $0 + $1.unreadCount } + folders.reduce(0) { $0 + $1.unreadCount }
        children = folders + feeds
    }

    init(feed: RssFeed) {
        id = feed.path
        kind = .feed
        name = feed.path.split(separator: "\\").last.map(String.init) ?? feed.title
        unreadCount = feed.unreadCount
        isLoading = feed.isLoading
        hasError = feed.hasError
        url = feed.url
        refreshInterval = feed.refreshInterval
        iconPath = feed.iconPath
        children = nil
    }

    init(unreadCount: Int64) {
        id = Self.unreadID
        kind = .unread
        name = String(localized: "Unread")
        self.unreadCount = unreadCount
        children = nil
    }
}
