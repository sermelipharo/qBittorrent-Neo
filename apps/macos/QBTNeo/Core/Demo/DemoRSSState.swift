import Foundation

/// RSS folders, feeds and download rules of the demo session, with the same
/// path rules as the core (`\`-separated item paths, "" = root).
struct DemoRSSState: Sendable {
    struct Feed: Sendable {
        var uid: String
        var url: String
        var path: String
        var title: String
        var lastBuildDate: String
        var isLoading = false
        var hasError = false
        var refreshInterval: Int64 = 0
        var articles: [RssArticle]
    }

    var folders: [String] = DemoRSSCatalog.folders
    var feeds: [Feed] = DemoRSSCatalog.feeds
    var rules: [RssAutoDownloadRule] = DemoRSSCatalog.rules

    // MARK: Paths

    static func parent(of path: String) -> String {
        guard let index = path.lastIndex(of: "\\") else { return "" }
        return String(path[..<index])
    }

    static func name(of path: String) -> String {
        guard let index = path.lastIndex(of: "\\") else { return path }
        return String(path[path.index(after: index)...])
    }

    private static func isInside(_ path: String, folder: String) -> Bool {
        folder.isEmpty || path.hasPrefix(folder + "\\")
    }

    func exists(_ path: String) -> Bool {
        path.isEmpty || folders.contains(path) || feeds.contains { $0.path == path }
    }

    private func feedIndex(_ path: String) -> Int? {
        feeds.firstIndex { $0.path == path }
    }

    // MARK: Tree

    func tree(withArticles: Bool) -> RssFolder {
        folder(at: "", withArticles: withArticles)
    }

    private func folder(at path: String, withArticles: Bool) -> RssFolder {
        let childFolders = folders.filter { Self.parent(of: $0) == path }
        let childFeeds = feeds.filter { Self.parent(of: $0.path) == path }
        return RssFolder(
            path: path,
            name: Self.name(of: path),
            folders: childFolders.map { folder(at: $0, withArticles: withArticles) },
            feeds: childFeeds.map { feed in
                RssFeed(
                    uid: feed.uid, url: feed.url, path: feed.path, title: feed.title, lastBuildDate: feed.lastBuildDate,
                    isLoading: feed.isLoading, hasError: feed.hasError, refreshInterval: feed.refreshInterval,
                    unreadCount: Int64(feed.articles.count { !$0.isRead }), articles: withArticles ? feed.articles : [],
                    iconPath: ""
                )
            }
        )
    }

    func articles(under path: String) throws -> [RssArticle] {
        guard exists(path) else { throw QbtError.NotFound(message: "Item doesn't exist: \(path).") }
        let selected = feeds.filter { $0.path == path || Self.isInside($0.path, folder: path) }
        return selected.flatMap(\.articles).sorted { $0.date > $1.date }
    }

    // MARK: Editing

    mutating func addFolder(_ path: String) throws {
        try checkNew(path)
        folders.append(path)
    }

    mutating func addFeed(url: String, path: String, interval: Int64) throws {
        let path = path.isEmpty ? url : path
        if feeds.contains(where: { $0.url == url }) {
            throw QbtError.Conflict(message: "RSS feed with given URL already exists: \(url).")
        }
        guard URL(string: url)?.scheme?.hasPrefix("http") == true else {
            throw QbtError.Conflict(message: "Invalid feed URL: \(url).")
        }
        try checkNew(path)
        feeds.append(Feed(
            uid: "{\(UUID().uuidString.lowercased())}", url: url, path: path, title: Self.name(of: path),
            lastBuildDate: "", isLoading: true, refreshInterval: max(interval, 0), articles: []
        ))
    }

    private func checkNew(_ path: String) throws {
        if exists(path) { throw QbtError.Conflict(message: "Item already exists: \(path).") }
        let parent = Self.parent(of: path)
        guard parent.isEmpty || folders.contains(parent) else {
            throw QbtError.Conflict(message: "Parent folder doesn't exist: \(parent).")
        }
    }

    mutating func setFeedURL(path: String, url: String) throws {
        guard let index = feedIndex(path) else { throw QbtError.Conflict(message: "Feed doesn't exist: \(path).") }
        if feeds.contains(where: { $0.url == url && $0.path != path }) {
            throw QbtError.Conflict(message: "RSS feed with given URL already exists: \(url).")
        }
        feeds[index].url = url
    }

    mutating func setRefreshInterval(path: String, seconds: Int64) throws {
        guard let index = feedIndex(path) else { throw QbtError.Conflict(message: "Feed doesn't exist: \(path).") }
        feeds[index].refreshInterval = max(seconds, 0)
    }

    mutating func remove(_ path: String) throws {
        guard !path.isEmpty, exists(path) else { throw QbtError.Conflict(message: "Item doesn't exist: \(path).") }
        folders.removeAll { $0 == path || Self.isInside($0, folder: path) }
        feeds.removeAll { $0.path == path || Self.isInside($0.path, folder: path) }
    }

    mutating func move(_ path: String, to destination: String) throws {
        guard !path.isEmpty, exists(path) else { throw QbtError.Conflict(message: "Item doesn't exist: \(path).") }
        guard !Self.isInside(destination, folder: path) else {
            throw QbtError.Conflict(message: "Can't move a folder into itself.")
        }
        try checkNew(destination)
        func moved(_ item: String) -> String {
            item == path ? destination : destination + item.dropFirst(path.count)
        }
        folders = folders.map { $0 == path || Self.isInside($0, folder: path) ? moved($0) : $0 }
        for index in feeds.indices where feeds[index].path == path || Self.isInside(feeds[index].path, folder: path) {
            feeds[index].path = moved(feeds[index].path)
        }
    }

    mutating func markAsRead(_ path: String, articleID: String?) {
        for index in feeds.indices where feeds[index].path == path || Self.isInside(feeds[index].path, folder: path) {
            for article in feeds[index].articles.indices where articleID == nil || feeds[index].articles[article].id == articleID {
                feeds[index].articles[article].isRead = true
            }
        }
    }

    mutating func refresh(_ path: String) {
        let now = Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year().hour().minute().second())
        for index in feeds.indices where feeds[index].path == path || Self.isInside(feeds[index].path, folder: path) {
            feeds[index].isLoading = false
            if !feeds[index].hasError { feeds[index].lastBuildDate = now }
            if feeds[index].articles.isEmpty, !feeds[index].hasError {
                feeds[index].articles = DemoRSSCatalog.genericArticles(feedTitle: feeds[index].title)
            }
        }
    }

    // MARK: Rules

    mutating func setRule(_ rule: RssAutoDownloadRule) {
        if let index = rules.firstIndex(where: { $0.name == rule.name }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
    }

    mutating func renameRule(_ old: String, to new: String) throws {
        guard let index = rules.firstIndex(where: { $0.name == old }) else {
            throw QbtError.NotFound(message: "Rule doesn't exist: \(old).")
        }
        if rules.contains(where: { $0.name == new }) {
            throw QbtError.Conflict(message: "A rule with this name already exists, please choose another name.")
        }
        rules[index].name = new
    }

    mutating func clearHistory(_ name: String) {
        for index in rules.indices where rules[index].name == name {
            rules[index].previouslyMatchedEpisodes = []
        }
    }

    func matches(for rule: RssAutoDownloadRule) -> [RssMatchingArticles] {
        let matcher = DemoRuleMatcher(rule: rule)
        return feeds.filter { rule.affectedFeeds.contains($0.url) }.compactMap { feed in
            let titles = feed.articles.map(\.title).filter(matcher.matches)
            return titles.isEmpty ? nil : RssMatchingArticles(feedName: Self.name(of: feed.path), articleTitles: titles)
        }
    }
}
