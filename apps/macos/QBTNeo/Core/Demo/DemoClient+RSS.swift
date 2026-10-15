import Foundation

extension DemoClient: RSSClient {
    private var rss: DemoFeatureStore { .shared }

    func rssTree(withArticles: Bool) -> RssFolder {
        rss.rss.withLock { $0.tree(withArticles: withArticles) }
    }

    func rssArticles(itemPath: String) throws -> [RssArticle] {
        try rss.rss.withLock { try $0.articles(under: itemPath) }
    }

    func rssAddFolder(path: String) throws {
        try rss.rss.withLock { try $0.addFolder(path) }
    }

    func rssAddFeed(url: String, path: String, refreshIntervalSecs: Int64) throws {
        try rss.rss.withLock { try $0.addFeed(url: url, path: path, interval: refreshIntervalSecs) }
    }

    func rssSetFeedUrl(path: String, url: String) throws {
        try rss.rss.withLock { try $0.setFeedURL(path: path, url: url) }
    }

    func rssSetFeedRefreshInterval(path: String, refreshIntervalSecs: Int64) throws {
        try rss.rss.withLock { try $0.setRefreshInterval(path: path, seconds: refreshIntervalSecs) }
    }

    func rssRemoveItem(path: String) throws {
        try rss.rss.withLock { try $0.remove(path) }
    }

    func rssMoveItem(itemPath: String, destPath: String) throws {
        try rss.rss.withLock { try $0.move(itemPath, to: destPath) }
    }

    func rssMarkAsRead(itemPath: String, articleId: String?) throws {
        rss.rss.withLock { $0.markAsRead(itemPath, articleID: articleId) }
    }

    func rssRefreshItem(itemPath: String) throws {
        rss.rss.withLock { $0.refresh(itemPath) }
    }

    func rssRules() -> [RssAutoDownloadRule] {
        rss.rss.withLock { $0.rules }
    }

    func rssSetRule(rule: RssAutoDownloadRule) throws {
        guard !rule.name.isEmpty else { throw QbtError.InvalidArgument(message: "Invalid rule name") }
        rss.rss.withLock { $0.setRule(rule) }
    }

    func rssRenameRule(oldName: String, newName: String) throws {
        try rss.rss.withLock { try $0.renameRule(oldName, to: newName) }
    }

    func rssRemoveRule(name: String) throws {
        rss.rss.withLock { $0.rules.removeAll { $0.name == name } }
    }

    func rssMatchingArticles(ruleName: String) throws -> [RssMatchingArticles] {
        try rss.rss.withLock { state in
            guard let rule = state.rules.first(where: { $0.name == ruleName }) else {
                throw QbtError.NotFound(message: "Rule doesn't exist: \(ruleName).")
            }
            return state.matches(for: rule)
        }
    }

    func rssPreviewRuleMatches(rule: RssAutoDownloadRule) -> [RssMatchingArticles] {
        rss.rss.withLock { $0.matches(for: rule) }
    }

    func rssClearRuleHistory(ruleName: String) throws {
        rss.rss.withLock { $0.clearHistory(ruleName) }
    }

    func rssImportRules(data: Data) throws {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            throw QbtError.InvalidArgument(message: "Invalid data format")
        }
        rss.rss.withLock { state in
            for (name, fields) in object {
                state.setRule(RssAutoDownloadRule(
                    name: name, enabled: fields["enabled"] as? Bool ?? true, priority: Int64(fields["priority"] as? Int ?? 0),
                    useRegex: fields["useRegex"] as? Bool ?? false, mustContain: fields["mustContain"] as? String ?? "",
                    mustNotContain: fields["mustNotContain"] as? String ?? "", episodeFilter: fields["episodeFilter"] as? String ?? "",
                    affectedFeeds: fields["affectedFeeds"] as? [String] ?? [], lastMatch: fields["lastMatch"] as? String ?? "",
                    ignoreDays: Int64(fields["ignoreDays"] as? Int ?? 0), smartFilter: fields["smartFilter"] as? Bool ?? false,
                    previouslyMatchedEpisodes: fields["previouslyMatchedEpisodes"] as? [String] ?? [],
                    torrentParams: .defaults
                ))
            }
        }
    }

    func rssExportRules() -> Data {
        let rules = rss.rss.withLock { $0.rules }
        var object: [String: Any] = [:]
        for rule in rules {
            object[rule.name] = [
                "enabled": rule.enabled, "priority": rule.priority, "useRegex": rule.useRegex, "mustContain": rule.mustContain,
                "mustNotContain": rule.mustNotContain, "episodeFilter": rule.episodeFilter, "affectedFeeds": rule.affectedFeeds,
                "lastMatch": rule.lastMatch, "ignoreDays": rule.ignoreDays, "smartFilter": rule.smartFilter,
                "previouslyMatchedEpisodes": rule.previouslyMatchedEpisodes,
            ]
        }
        return (try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])) ?? Data("{}".utf8)
    }

    func rssExportRulesLegacy() -> Data {
        rssExportRules()
    }

    func rssValidateRuleExpression(expression: String, useRegex: Bool) -> String {
        guard useRegex, !expression.isEmpty else { return "" }
        do {
            _ = try NSRegularExpression(pattern: expression)
            return ""
        } catch {
            return String(localized: "Invalid regular expression")
        }
    }

    func rssIsValidEpisodeFilter(filter: String) -> Bool {
        guard !filter.isEmpty else { return true }
        let pattern = #"^(^\d{1,4}x(\d{1,4}(-(\d{1,4})?)?;){1,}){1,1}"#
        return filter.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
