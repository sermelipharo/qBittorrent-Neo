import Foundation
import Observation

/// RSS Downloader state (features.md §3.25, §5.12.3): rules, the editor of
/// the single selected rule (saved automatically), the affected-feeds
/// checklist and the live matching-articles preview.
@Observable @MainActor
final class RSSDownloaderModel {
    private(set) var rules: [RssAutoDownloadRule] = []
    var selection: Set<String> = [] {
        didSet { if selection != oldValue { selectionChanged() } }
    }
    /// Draft of the single selected rule.
    var draft: RssAutoDownloadRule? {
        didSet { if draft != oldValue, oldValue?.name == draft?.name, draft != nil { scheduleSave() } }
    }
    private(set) var feeds: [(name: String, url: String)] = []
    private(set) var matches: [RssMatchingArticles] = []
    private(set) var mustContainError = ""
    private(set) var mustNotContainError = ""
    private(set) var episodeFilterValid = true
    var alert: RSSAlert?

    @ObservationIgnored private var client: (any RSSClient)?
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    func attach(_ client: (any CoreClient)?) async {
        guard let client = client as? any RSSClient else { return }
        self.client = client
        await reload()
        if selection.isEmpty, let first = rules.first { selection = [first.name] }
    }

    func reload() async {
        guard let client else { return }
        let (rules, tree) = await CoreCall.run { (client.rssRules(), client.rssTree(withArticles: false)) }
        self.rules = rules.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        var list: [(String, String)] = []
        collectFeeds(tree, into: &list)
        feeds = list.sorted { $0.0.localizedStandardCompare($1.0) == .orderedAscending }
        selection = selection.filter { name in self.rules.contains { $0.name == name } }
        if draft == nil || !selection.contains(draft?.name ?? "") { selectionChanged() }
        updatePreview()
    }

    private func collectFeeds(_ folder: RssFolder, into list: inout [(String, String)]) {
        for feed in folder.feeds {
            list.append((feed.path.split(separator: "\\").last.map(String.init) ?? feed.title, feed.url))
        }
        for child in folder.folders { collectFeeds(child, into: &list) }
    }

    var selectedRules: [RssAutoDownloadRule] { rules.filter { selection.contains($0.name) } }

    // MARK: Editing

    private func selectionChanged() {
        flushSave()
        draft = selection.count == 1 ? rules.first { selection.contains($0.name) } : nil
        validate()
        updatePreview()
    }

    private func scheduleSave() {
        validate()
        updatePreview()
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            self?.flushSave()
        }
    }

    /// Writes the draft to the core now (selection change, window close).
    func flushSave() {
        saveTask?.cancel()
        saveTask = nil
        guard let draft, let index = rules.firstIndex(where: { $0.name == draft.name }), rules[index] != draft else { return }
        do {
            try client?.rssSetRule(rule: draft)
            rules[index] = draft
        } catch {
            alert = RSSAlert(title: "qBittorrent Neo", message: error.userMessage)
        }
    }

    private func validate() {
        guard let draft, let client else {
            mustContainError = ""
            mustNotContainError = ""
            episodeFilterValid = true
            return
        }
        mustContainError = client.rssValidateRuleExpression(expression: draft.mustContain, useRegex: draft.useRegex)
        mustNotContainError = client.rssValidateRuleExpression(expression: draft.mustNotContain, useRegex: draft.useRegex)
        episodeFilterValid = client.rssIsValidEpisodeFilter(filter: draft.episodeFilter)
    }

    /// Matching articles of the selected rules, using unsaved edits.
    private func updatePreview() {
        guard let client else { return }
        let targets = draft.map { [$0] } ?? selectedRules
        var byFeed: [String: Set<String>] = [:]
        for rule in targets {
            for match in client.rssPreviewRuleMatches(rule: rule) {
                byFeed[match.feedName, default: []].formUnion(match.articleTitles)
            }
        }
        matches = byFeed.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }.map { feed in
            RssMatchingArticles(feedName: feed, articleTitles: (byFeed[feed] ?? []).sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        }
    }

    // MARK: Rule list

    func setEnabled(_ name: String, _ enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.name == name }) else { return }
        var rule = rules[index]
        rule.enabled = enabled
        do {
            try client?.rssSetRule(rule: rule)
            rules[index] = rule
            if draft?.name == name { draft?.enabled = enabled }
        } catch {
            alert = RSSAlert(title: "qBittorrent Neo", message: error.userMessage)
        }
    }

    subscript(enabled name: String) -> Bool {
        get { rules.first { $0.name == name }?.enabled ?? false }
        set { setEnabled(name, newValue) }
    }

    /// Returns an error message when the name is taken.
    func addRule(named name: String) async -> String? {
        let name = name.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        if rules.contains(where: { $0.name == name }) {
            return String(localized: "A rule with this name already exists, please choose another name.")
        }
        let rule = RssAutoDownloadRule(
            name: name, enabled: true, priority: 0, useRegex: false, mustContain: "", mustNotContain: "", episodeFilter: "",
            affectedFeeds: [], lastMatch: "", ignoreDays: 0, smartFilter: false, previouslyMatchedEpisodes: [], torrentParams: .defaults
        )
        do {
            try client?.rssSetRule(rule: rule)
            await reload()
            selection = [name]
            return nil
        } catch {
            return error.userMessage
        }
    }

    func renameRule(_ old: String, to new: String) async -> String? {
        let new = new.trimmingCharacters(in: .whitespaces)
        guard !new.isEmpty, new != old else { return nil }
        if rules.contains(where: { $0.name == new }) {
            return String(localized: "A rule with this name already exists, please choose another name.")
        }
        flushSave()
        do {
            try client?.rssRenameRule(oldName: old, newName: new)
            await reload()
            selection = [new]
            return nil
        } catch {
            return error.userMessage
        }
    }

    func removeRules(_ names: Set<String>) async {
        saveTask?.cancel()
        draft = nil
        for name in names { try? client?.rssRemoveRule(name: name) }
        selection = []
        await reload()
    }

    func clearHistory() async {
        guard let name = draft?.name ?? selection.first else { return }
        try? client?.rssClearRuleHistory(ruleName: name)
        await reload()
        draft?.previouslyMatchedEpisodes = []
    }

    // MARK: Affected feeds (tri-state across the selected rules)

    func feedState(_ url: String) -> FeedCheckState {
        let rules = draft.map { [$0] } ?? selectedRules
        let count = rules.count { $0.affectedFeeds.contains(url) }
        return count == 0 ? .off : (count == rules.count ? .on : .mixed)
    }

    func setFeed(_ url: String, included: Bool) {
        if var rule = draft {
            rule.affectedFeeds.removeAll { $0 == url }
            if included { rule.affectedFeeds.append(url) }
            draft = rule
            return
        }
        for var rule in selectedRules {
            rule.affectedFeeds.removeAll { $0 == url }
            if included { rule.affectedFeeds.append(url) }
            try? client?.rssSetRule(rule: rule)
        }
        Task { await reload() }
    }

    // MARK: Import / export

    func importRules(from url: URL) async {
        do {
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= 10 * 1_024 * 1_024 else {
                alert = RSSAlert(title: String(localized: "Import error"), message: String(localized: "Failed to read the file. File is too large."))
                return
            }
            let data = try Data(contentsOf: url)
            try client?.rssImportRules(data: data)
            await reload()
        } catch let error as QbtError {
            alert = RSSAlert(title: String(localized: "Import error"),
                             message: String(localized: "Failed to import the selected rules file. Reason: \(error.userMessage)"))
        } catch {
            alert = RSSAlert(title: String(localized: "Import error"), message: String(localized: "Failed to read the file. \(error.localizedDescription)"))
        }
    }

    func exportData(legacy: Bool) -> Data? {
        guard let client else { return nil }
        return legacy ? client.rssExportRulesLegacy() : client.rssExportRules()
    }
}
