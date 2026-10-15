import Foundation

// Application, RSS, search and torrent-creator calls of the C++ core.

extension QtCoreClient: AppInfoClient {
    func networkInterfaces() -> [NetworkInterface] {
        bridge.value("networkInterfaces", fallback: [])
    }

    func networkInterfaceAddresses(interface: String) -> [String] {
        bridge.value("networkInterfaceAddresses", ["interface": interface], fallback: [])
    }

    func cookies() -> [Cookie] {
        bridge.value("cookies", fallback: [])
    }

    func setCookies(cookies: [Cookie]) throws {
        try bridge.callVoid("setCookies", ["cookies": cookies])
    }

    func sendTestEmail() async throws {
        try await bridge.callAsyncVoid("sendTestEmail")
    }

    func setPreferencesJson(json: String) throws {
        try bridge.callVoid("setPreferencesJson", ["json": json])
    }

    func webuiStatus() -> WebUiStatus {
        bridge.value("webuiStatus", fallback: .neoEmpty)
    }

    func hashUiLockPassword(password: String) async throws -> String {
        try await bridge.callAsync("hashUiLockPassword", ["password": password])
    }

    func verifyUiLockPassword(stored: String, password: String) async throws -> Bool {
        try await bridge.callAsync("verifyUiLockPassword", ["stored": stored, "password": password])
    }

    func fetchTrackerFavicon(trackerUrl: String) async throws -> Data {
        try await bridge.callAsync("fetchTrackerFavicon", ["trackerUrl": trackerUrl])
    }
}

extension QtCoreClient: RSSClient {
    func rssTree(withArticles: Bool) -> RssFolder {
        bridge.value("rssTree", ["withArticles": withArticles], fallback: .neoEmpty)
    }

    func rssArticles(itemPath: String) throws -> [RssArticle] {
        try bridge.call("rssArticles", ["itemPath": itemPath])
    }

    func rssAddFolder(path: String) throws {
        try bridge.callVoid("rssAddFolder", ["path": path])
    }

    func rssAddFeed(url: String, path: String, refreshIntervalSecs: Int64) throws {
        try bridge.callVoid("rssAddFeed", ["url": url, "path": path, "refreshIntervalSecs": refreshIntervalSecs])
    }

    func rssSetFeedUrl(path: String, url: String) throws {
        try bridge.callVoid("rssSetFeedUrl", ["path": path, "url": url])
    }

    func rssSetFeedRefreshInterval(path: String, refreshIntervalSecs: Int64) throws {
        try bridge.callVoid("rssSetFeedRefreshInterval", ["path": path, "refreshIntervalSecs": refreshIntervalSecs])
    }

    func rssRemoveItem(path: String) throws {
        try bridge.callVoid("rssRemoveItem", ["path": path])
    }

    func rssMoveItem(itemPath: String, destPath: String) throws {
        try bridge.callVoid("rssMoveItem", ["itemPath": itemPath, "destPath": destPath])
    }

    func rssMarkAsRead(itemPath: String, articleId: String?) throws {
        try bridge.callVoid("rssMarkAsRead", ["itemPath": itemPath, "articleId": articleId])
    }

    func rssRefreshItem(itemPath: String) throws {
        try bridge.callVoid("rssRefreshItem", ["itemPath": itemPath])
    }

    func rssRules() -> [RssAutoDownloadRule] {
        bridge.value("rssRules", fallback: [])
    }

    func rssSetRule(rule: RssAutoDownloadRule) throws {
        try bridge.callVoid("rssSetRule", ["rule": rule])
    }

    func rssRenameRule(oldName: String, newName: String) throws {
        try bridge.callVoid("rssRenameRule", ["oldName": oldName, "newName": newName])
    }

    func rssRemoveRule(name: String) throws {
        try bridge.callVoid("rssRemoveRule", ["name": name])
    }

    func rssMatchingArticles(ruleName: String) throws -> [RssMatchingArticles] {
        try bridge.call("rssMatchingArticles", ["ruleName": ruleName])
    }

    func rssPreviewRuleMatches(rule: RssAutoDownloadRule) -> [RssMatchingArticles] {
        bridge.value("rssPreviewRuleMatches", ["rule": rule], fallback: [])
    }

    func rssClearRuleHistory(ruleName: String) throws {
        try bridge.callVoid("rssClearRuleHistory", ["ruleName": ruleName])
    }

    func rssImportRules(data: Data) throws {
        try bridge.callVoid("rssImportRules", ["data": data])
    }

    func rssExportRules() -> Data {
        bridge.value("rssExportRules", fallback: Data())
    }

    func rssExportRulesLegacy() -> Data {
        bridge.value("rssExportRulesLegacy", fallback: Data())
    }

    func rssValidateRuleExpression(expression: String, useRegex: Bool) -> String {
        bridge.value("rssValidateRuleExpression", ["expression": expression, "useRegex": useRegex], fallback: "")
    }

    func rssIsValidEpisodeFilter(filter: String) -> Bool {
        bridge.value("rssIsValidEpisodeFilter", ["filter": filter], fallback: false)
    }
}

extension QtCoreClient: SearchClient {
    func searchEngineStatus() -> SearchEngineStatus {
        bridge.value("searchEngineStatus", fallback: .neoEmpty)
    }

    func searchPlugins() -> [SearchPlugin] {
        bridge.value("searchPlugins", fallback: [])
    }

    func searchInstallPlugins(sources: [String]) async throws {
        try await bridge.callAsyncVoid("searchInstallPlugins", ["sources": sources])
    }

    func searchUninstallPlugins(names: [String]) throws {
        try bridge.callVoid("searchUninstallPlugins", ["names": names])
    }

    func searchEnablePlugins(names: [String], enable: Bool) throws {
        try bridge.callVoid("searchEnablePlugins", ["names": names, "enable": enable])
    }

    func searchUpdatePlugins() async throws {
        try await bridge.callAsyncVoid("searchUpdatePlugins")
    }

    func searchStart(pattern: String, plugins: [String], category: String) throws -> Int64 {
        try bridge.call("searchStart", ["pattern": pattern, "plugins": plugins, "category": category])
    }

    func searchStop(id: Int64) throws {
        try bridge.callVoid("searchStop", ["id": id])
    }

    func searchStatus(id: Int64?) throws -> [SearchJobInfo] {
        try bridge.call("searchStatus", ["id": id])
    }

    func searchResults(id: Int64, limit: Int64, offset: Int64) throws -> SearchResultsPage {
        try bridge.call("searchResults", ["id": id, "limit": limit, "offset": offset])
    }

    func searchDelete(id: Int64) throws {
        try bridge.callVoid("searchDelete", ["id": id])
    }

    func searchDownloadTorrent(url: String, plugin: String, params: AddTorrentParams) async throws {
        try await bridge.callAsyncVoid("searchDownloadTorrent", ["url": url, "plugin": plugin, "params": params])
    }
}

extension QtCoreClient: CreatorClient {
    func creatorAddTask(params: TorrentCreatorParams) throws -> String {
        try bridge.call("creatorAddTask", ["params": params])
    }

    func creatorTasks() -> [CreatorTask] {
        bridge.value("creatorTasks", fallback: [])
    }

    func creatorTask(id: String) throws -> CreatorTask {
        try bridge.call("creatorTask", ["id": id])
    }

    func creatorTorrentFile(id: String) throws -> Data {
        try bridge.call("creatorTorrentFile", ["id": id])
    }

    func creatorDeleteTask(id: String) throws {
        try bridge.callVoid("creatorDeleteTask", ["id": id])
    }

    func creatorAutoPieceSize(totalSize: Int64, format: TorrentFormat) -> Int64 {
        bridge.value("creatorAutoPieceSize", ["totalSize": totalSize, "format": format], fallback: 0)
    }

    func creatorCalculatePieces(sourcePath: String, pieceSize: Int64, format: TorrentFormat) async throws -> Int64 {
        try await bridge.callAsync("creatorCalculatePieces", ["sourcePath": sourcePath, "pieceSize": pieceSize, "format": format])
    }
}
