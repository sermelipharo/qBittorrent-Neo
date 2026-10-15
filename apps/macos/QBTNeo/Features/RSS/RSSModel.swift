import AppKit
import Observation

/// RSS reader state (features.md §3.35, §5.12): the feed tree, the article
/// list of the selected items and the reader actions.
@Observable @MainActor
final class RSSModel {
    private(set) var nodes: [RSSNode] = []
    var selection: Set<RSSNode.ID> = [RSSNode.unreadID] {
        didSet { if selection != oldValue { rebuildArticles() } }
    }
    private(set) var articles: [RSSArticleItem] = []
    var articleSelection: Set<RSSArticleItem.ID> = [] {
        didSet { articleSelectionChanged(from: oldValue) }
    }
    var filter = "" {
        didSet { if filter != oldValue { rebuildArticles() } }
    }
    var alert: RSSAlert?
    var sheet: RSSSheet?
    var pendingDeletion: [RSSNode]?

    @ObservationIgnored private(set) var client: (any RSSClient)?
    @ObservationIgnored private var tree = RssFolder(path: "", name: "", folders: [], feeds: [])
    @ObservationIgnored private var nodeIndex: [String: RSSNode] = [:]
    @ObservationIgnored private var currentArticleID: RSSArticleItem.ID?

    var totalUnread: Int64 { nodes.first?.unreadCount ?? 0 }

    // MARK: Loading

    func attach(_ client: (any CoreClient)?) async {
        guard let client = client as? any RSSClient else { return }
        self.client = client
        await reload()
    }

    func reload() async {
        guard let client else { return }
        tree = await CoreCall.run { client.rssTree(withArticles: true) }
        let root = RSSNode(folder: tree)
        nodes = [RSSNode(unreadCount: root.unreadCount)] + (root.children ?? [])
        nodeIndex = [:]
        index(nodes)
        selection = selection.filter { nodeIndex[$0] != nil }
        if selection.isEmpty { selection = [RSSNode.unreadID] }
        rebuildArticles()
    }

    /// Reloads on RSS events (debounced) and every few seconds while shown.
    func observe(_ events: AsyncStream<CoreEvent>) async {
        for await event in events {
            guard case .rssUpdated = event else { continue }
            try? await Task.sleep(for: .milliseconds(300))
            await reload()
        }
    }

    private func index(_ list: [RSSNode]) {
        for node in list {
            nodeIndex[node.id] = node
            if let children = node.children { index(children) }
        }
    }

    func node(_ id: RSSNode.ID) -> RSSNode? { nodeIndex[id] }

    var selectedNodes: [RSSNode] { selection.compactMap { nodeIndex[$0] } }

    /// Single selected node (for rename, feed options).
    var singleSelection: RSSNode? {
        selection.count == 1 ? selection.first.flatMap { nodeIndex[$0] } : nil
    }

    var showsFeedColumn: Bool { selection.contains(RSSNode.unreadID) }

    // MARK: Articles

    private func rebuildArticles() {
        var items: [RSSArticleItem] = []
        let selectedPaths = selectedNodes.map(\.path)
        let unreadView = selection.contains(RSSNode.unreadID)
        collect(tree, into: &items) { feed in
            unreadView || selectedPaths.contains { path in
                path == feed.path || feed.path.hasPrefix(path + "\\")
            }
        }
        if unreadView {
            let keep = Set(articles.filter { articleSelection.contains($0.id) }.map(\.id))
            items = items.filter { !$0.article.isRead || keep.contains($0.id) }
        }
        let query = filter.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty { items = items.filter { $0.article.title.localizedStandardContains(query) } }
        var seen = Set<String>()
        articles = items.sorted { $0.article.date > $1.article.date }.filter { seen.insert($0.id).inserted }
        articleSelection = articleSelection.filter { id in articles.contains { $0.id == id } }
    }

    private func collect(_ folder: RssFolder, into items: inout [RSSArticleItem], where include: (RssFeed) -> Bool) {
        for feed in folder.feeds where include(feed) {
            items += feed.articles.map { RSSArticleItem(article: $0, feed: feed) }
        }
        for child in folder.folders { collect(child, into: &items, where: include) }
    }

    var currentArticle: RSSArticleItem? {
        guard articleSelection.count == 1, let id = articleSelection.first else { return nil }
        return articles.first { $0.id == id }
    }

    /// The previously current article is marked read when another one
    /// becomes current (qBittorrent's article list behaviour).
    private func articleSelectionChanged(from old: Set<RSSArticleItem.ID>) {
        guard articleSelection != old else { return }
        if let previous = currentArticleID, previous != currentArticle?.id {
            markArticleRead(previous)
        }
        currentArticleID = currentArticle?.id
    }

    func markArticleRead(_ id: RSSArticleItem.ID) {
        guard let index = articles.firstIndex(where: { $0.id == id }), !articles[index].article.isRead else { return }
        let item = articles[index]
        articles[index].article.isRead = true
        try? client?.rssMarkAsRead(itemPath: item.feedPath, articleId: item.article.id)
        Task { await reloadCounts() }
    }

    /// Refreshes unread counts without dropping read rows from the Unread view.
    private func reloadCounts() async {
        guard let client else { return }
        tree = await CoreCall.run { client.rssTree(withArticles: true) }
        let root = RSSNode(folder: tree)
        nodes = [RSSNode(unreadCount: root.unreadCount)] + (root.children ?? [])
        nodeIndex = [:]
        index(nodes)
    }

    // MARK: Feed actions

    /// Destination folder for new items: the selected folder, the parent of
    /// a selected feed, or the root.
    var destinationFolder: String {
        guard let node = selectedNodes.first else { return "" }
        switch node.kind {
        case .unread: return ""
        case .folder: return node.path
        case .feed: return node.parentPath
        }
    }

    func addFeed(url: String, refreshInterval: Int64) async -> Bool {
        let url = url.trimmingCharacters(in: .whitespaces)
        let folder = destinationFolder
        let path = folder.isEmpty ? url : folder + "\\" + url
        do {
            try client?.rssAddFeed(url: url, path: path, refreshIntervalSecs: refreshInterval)
            await reload()
            selection = [path]
            return true
        } catch {
            alert = RSSAlert(title: "qBittorrent Neo", message: error.userMessage)
            return false
        }
    }

    func setFeedOptions(_ node: RSSNode, url: String, refreshInterval: Int64) async -> Bool {
        do {
            try client?.rssSetFeedRefreshInterval(path: node.path, refreshIntervalSecs: refreshInterval)
            try client?.rssSetFeedUrl(path: node.path, url: url.trimmingCharacters(in: .whitespaces))
            await reload()
            return true
        } catch {
            alert = RSSAlert(title: "qBittorrent Neo", message: error.userMessage)
            return false
        }
    }

    func addFolder(named name: String) async {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let folder = destinationFolder
        let path = folder.isEmpty ? name : folder + "\\" + name
        do {
            try client?.rssAddFolder(path: path)
            await reload()
        } catch {
            alert = RSSAlert(title: "qBittorrent Neo", message: error.userMessage)
        }
    }

    /// Renames by moving the item within its parent folder.
    func rename(_ node: RSSNode, to name: String) async -> Bool {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, name != node.name else { return true }
        let destination = node.parentPath.isEmpty ? name : node.parentPath + "\\" + name
        do {
            try client?.rssMoveItem(itemPath: node.path, destPath: destination)
            await reload()
            selection = [destination]
            return true
        } catch {
            alert = RSSAlert(title: String(localized: "Rename failed"), message: error.userMessage)
            return false
        }
    }

    func move(_ ids: [RSSNode.ID], into folder: String) async {
        for id in ids where id != RSSNode.unreadID {
            guard let node = nodeIndex[id], node.parentPath != folder, id != folder else { continue }
            let destination = folder.isEmpty ? node.name : folder + "\\" + node.name
            do {
                try client?.rssMoveItem(itemPath: node.path, destPath: destination)
            } catch {
                alert = RSSAlert(title: "qBittorrent Neo", message: error.userMessage)
            }
        }
        await reload()
    }

    func delete(_ nodes: [RSSNode]) async {
        for node in nodes where node.kind != .unread {
            try? client?.rssRemoveItem(path: node.path)
        }
        selection = [RSSNode.unreadID]
        await reload()
    }

    /// "Update": selected items, or everything when "Unread" is selected.
    func update(_ nodes: [RSSNode]) {
        let paths = nodes.contains { $0.kind == .unread } ? [""] : nodes.map(\.path)
        for path in paths { try? client?.rssRefreshItem(itemPath: path) }
        Task { await reload() }
    }

    func updateAll() {
        update([RSSNode(unreadCount: 0)])
    }

    func markRead(_ nodes: [RSSNode]) {
        let paths = nodes.contains { $0.kind == .unread } ? [""] : nodes.map(\.path)
        for path in paths { try? client?.rssMarkAsRead(itemPath: path, articleId: nil) }
        Task { await reload() }
    }

    func copyFeedURLs(_ nodes: [RSSNode]) {
        let urls = nodes.filter { $0.kind == .feed }.map(\.url).joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(urls, forType: .string)
    }

    // MARK: Article actions

    var selectedArticles: [RSSArticleItem] { articles.filter { articleSelection.contains($0.id) } }

    /// Downloads the torrents of the articles; only http(s), magnet links and
    /// info hashes are accepted (others may be malicious).
    func download(_ items: [RSSArticleItem], app: AppModel) {
        var blocked: [String] = []
        for item in items {
            markArticleRead(item.id)
            let url = item.article.torrentUrl.trimmingCharacters(in: .whitespaces)
            guard !url.isEmpty else { continue }
            guard RSSLinkPolicy.isSupportedTorrentURL(url) else {
                blocked.append(item.article.title)
                app.appendLocalLog("""
                    Blocked adding torrent from RSS article. Unsupported torrent URL. Only HTTP(S) URLs, magnet URIs and info \
                    hashes are supported. Article: "\(item.article.title)". URL: "\(url)".
                    """)
                continue
            }
            app.add(.url(url: url))
        }
        if let first = blocked.first {
            alert = RSSAlert(title: "qBittorrent Neo", message: RSSLinkPolicy.summary(
                String(localized: """
                    Blocked adding torrent from RSS article. The following article has an unsupported torrent URL and it may \
                    be malicious behaviour:
                    \(first)
                    """), extra: blocked.count - 1))
        }
    }

    /// Opens the articles' news links in the browser (never `file:` URLs).
    func openNewsURLs(_ items: [RSSArticleItem], app: AppModel) {
        var blocked: [String] = []
        var empty: [String] = []
        for item in items {
            markArticleRead(item.id)
            let link = item.article.link.trimmingCharacters(in: .whitespaces)
            guard !link.isEmpty, let url = URL(string: link) else {
                empty.append(item.article.title)
                continue
            }
            guard RSSLinkPolicy.isWebURL(url) else {
                blocked.append(item.article.title)
                app.appendLocalLog("""
                    Blocked opening RSS article URL. URL pointing to local file might be malicious behaviour. \
                    Article: "\(item.article.title)". URL: "\(link)".
                    """)
                continue
            }
            NSWorkspace.shared.open(url)
        }
        if let first = blocked.first {
            alert = RSSAlert(title: "qBittorrent Neo", message: RSSLinkPolicy.summary(
                String(localized: """
                    Blocked opening RSS article URL. The following article URL is pointing to local file and it may be \
                    malicious behaviour:
                    \(first)
                    """), extra: blocked.count - 1))
        } else if let first = empty.first {
            alert = RSSAlert(title: "qBittorrent Neo", message: RSSLinkPolicy.summary(
                String(localized: "The following article has no news URL provided:\n\(first)"), extra: empty.count - 1))
        }
    }
}
