import Foundation

/// RSS reader and auto-downloader calls of the core facade (`api_rss.rs`).
///
/// Item paths use `\` as the folder separator; "" is the root folder.
protocol RSSClient: AnyObject, Sendable {
    func rssTree(withArticles: Bool) -> RssFolder
    func rssArticles(itemPath: String) throws -> [RssArticle]
    func rssAddFolder(path: String) throws
    func rssAddFeed(url: String, path: String, refreshIntervalSecs: Int64) throws
    func rssSetFeedUrl(path: String, url: String) throws
    func rssSetFeedRefreshInterval(path: String, refreshIntervalSecs: Int64) throws
    func rssRemoveItem(path: String) throws
    func rssMoveItem(itemPath: String, destPath: String) throws
    func rssMarkAsRead(itemPath: String, articleId: String?) throws
    func rssRefreshItem(itemPath: String) throws

    func rssRules() -> [RssAutoDownloadRule]
    func rssSetRule(rule: RssAutoDownloadRule) throws
    func rssRenameRule(oldName: String, newName: String) throws
    func rssRemoveRule(name: String) throws
    func rssMatchingArticles(ruleName: String) throws -> [RssMatchingArticles]
    func rssPreviewRuleMatches(rule: RssAutoDownloadRule) -> [RssMatchingArticles]
    func rssClearRuleHistory(ruleName: String) throws
    func rssImportRules(data: Data) throws
    func rssExportRules() -> Data
    func rssExportRulesLegacy() -> Data
    func rssValidateRuleExpression(expression: String, useRegex: Bool) -> String
    func rssIsValidEpisodeFilter(filter: String) -> Bool
}
