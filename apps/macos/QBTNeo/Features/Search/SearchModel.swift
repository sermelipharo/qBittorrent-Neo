import AppKit
import Observation

/// Search window state (features.md §3.36, §5.8): Python status, plugins,
/// the query row, result tabs, history and result actions.
@Observable @MainActor
final class SearchModel {
    private(set) var engineStatus: SearchEngineStatus?
    private(set) var plugins: [SearchPlugin] = []
    var pattern = ""
    var category = "all"
    /// "enabled", "all", or a plugin name.
    var pluginSelector = "enabled"
    private(set) var tabs: [SearchTabModel] = []
    var currentTabID: SearchTabModel.ID? {
        didSet { if currentTabID != oldValue { saveSession() } }
    }
    private(set) var history: [String] = []
    var alert: RSSAlert?

    @ObservationIgnored private(set) var client: (any SearchClient)?
    @ObservationIgnored private var store: SearchSessionStore?
    @ObservationIgnored private var isRestoring = false

    init() {
        history = AppDefaults.store.stringArray(forKey: FeatureDefaults.searchHistory) ?? []
    }

    /// `profileRoot` locates the saved tabs; nil (snapshots) disables storing.
    func attach(_ client: (any CoreClient)?, profileRoot: String?) async {
        guard let client = client as? any SearchClient else { return }
        self.client = client
        if self.store == nil, let profileRoot { store = SearchSessionStore(profileRoot: profileRoot) }
        await reloadPlugins()
        await restoreSession()
    }

    func reloadPlugins() async {
        guard let client else { return }
        let (status, plugins) = await CoreCall.run { (client.searchEngineStatus(), client.searchPlugins()) }
        engineStatus = status
        self.plugins = plugins.sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
        if pluginSelector != "enabled", pluginSelector != "all", !self.plugins.contains(where: { $0.name == pluginSelector && $0.enabled }) {
            pluginSelector = "enabled"
        }
    }

    var enabledPlugins: [SearchPlugin] { plugins.filter(\.enabled) }

    /// Categories supported by the plugins of the current selector.
    var categories: [SearchCategory] {
        let selected = switch pluginSelector {
        case "all": plugins
        case "enabled": enabledPlugins
        default: plugins.filter { $0.name == pluginSelector }
        }
        var seen = Set<String>()
        return selected.flatMap(\.supportedCategories)
            .filter { $0.id != "all" && seen.insert($0.id).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var currentTab: SearchTabModel? { tabs.first { $0.id == currentTabID } }

    /// Stop is shown when the query equals the current tab's running search.
    var showsStop: Bool {
        guard let tab = currentTab else { return false }
        return tab.status == .ongoing && tab.pattern == pattern.trimmingCharacters(in: .whitespaces)
    }

    // MARK: Searching

    func search() {
        let text = pattern.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else {
            alert = RSSAlert(title: String(localized: "Empty search pattern"), message: String(localized: "Please type a search pattern first"))
            return
        }
        guard engineStatus?.pythonFound == true else {
            alert = RSSAlert(title: String(localized: "Search Engine"), message: String(localized: "Please install Python to use the Search Engine."))
            return
        }
        guard let client else { return }
        do {
            let id = try client.searchStart(pattern: text, plugins: [pluginSelector], category: category)
            let tab = SearchTabModel(jobID: id, pattern: text, client: client)
            adopt(tab)
            tabs.append(tab)
            currentTabID = tab.id
            saveSession()
            remember(text)
        } catch {
            alert = RSSAlert(title: String(localized: "Search Engine"), message: error.userMessage)
        }
    }

    func stopCurrent() {
        currentTab?.stop()
    }

    func refresh(_ tab: SearchTabModel) {
        guard let client, let id = try? client.searchStart(pattern: tab.pattern, plugins: [pluginSelector], category: category) else { return }
        tab.restart(jobID: id)
    }

    func close(_ tab: SearchTabModel) {
        tab.close()
        tabs.removeAll { $0.id == tab.id }
        if currentTabID == tab.id { currentTabID = tabs.last?.id }
        deleteStoredResults(of: tab)
        saveSession()
    }

    func closeAll() {
        for tab in tabs {
            tab.close()
            deleteStoredResults(of: tab)
        }
        tabs = []
        currentTabID = nil
        saveSession()
    }

    // MARK: Stored session

    private var storesTabs: Bool { AppDefaults.store.bool(forKey: FeatureDefaults.storeSearchTabs) }
    private var storesResults: Bool { storesTabs && AppDefaults.store.bool(forKey: FeatureDefaults.storeSearchResults) }

    private func adopt(_ tab: SearchTabModel) {
        tab.didStop = { [weak self] tab in self?.storeResults(of: tab) }
    }

    /// Writes the open tabs (pattern and current tab) when "Store opened tabs" is on.
    private func saveSession() {
        guard !isRestoring, storesTabs, let store else { return }
        let session = SearchSessionStore.Session(
            tabs: tabs.map { .init(id: $0.id.uuidString, pattern: $0.pattern) },
            currentTab: currentTabID?.uuidString ?? ""
        )
        Task { await store.saveSession(session) }
    }

    private func storeResults(of tab: SearchTabModel) {
        guard storesResults, let store, tabs.contains(where: { $0.id == tab.id }) else { return }
        let results = tab.results
        let id = tab.id.uuidString
        Task { await store.saveResults(results, id: id) }
    }

    private func deleteStoredResults(of tab: SearchTabModel) {
        guard let store else { return }
        let id = tab.id.uuidString
        Task { await store.deleteResults(id: id) }
    }

    /// Applies a change of the "Store opened tabs" / "Also store search
    /// results" options: turning one off deletes what it stored, turning
    /// results on writes the current results (features.md §5.8.1).
    func storageSettingsChanged() {
        guard let store else { return }
        if !storesTabs {
            Task { await store.deleteAll(includingSession: true) }
        } else if !storesResults {
            Task { await store.deleteAll(includingSession: false) }
            saveSession()
        } else {
            saveSession()
            for tab in tabs where tab.status != .ongoing { storeResults(of: tab) }
        }
    }

    /// Recreates the saved tabs (once, when no tab is open yet).
    private func restoreSession() async {
        guard let store, let client else { return }
        guard storesTabs else {
            await store.deleteAll(includingSession: true)
            return
        }
        if !storesResults { await store.deleteAll(includingSession: false) }
        guard tabs.isEmpty, let session = await store.loadSession() else { return }
        isRestoring = true
        defer { isRestoring = false }
        for entry in session.tabs {
            guard let id = UUID(uuidString: entry.id) else { continue }
            let results = storesResults ? await store.loadResults(id: entry.id) : []
            let tab = SearchTabModel(restoredID: id, pattern: entry.pattern, results: results, client: client)
            adopt(tab)
            tabs.append(tab)
        }
        currentTabID = tabs.first { $0.id.uuidString == session.currentTab }?.id ?? tabs.last?.id
        if let tab = currentTab, pattern.isEmpty { pattern = tab.pattern }
    }

    private func remember(_ text: String) {
        let limit = FeatureDefaults.searchHistoryLimit
        guard limit > 0 else { return }
        history.removeAll { $0 == text }
        history.append(text)
        if history.count > limit { history.removeFirst(history.count - limit) }
        AppDefaults.store.set(history, forKey: FeatureDefaults.searchHistory)
    }

    // MARK: Result actions

    /// Magnet links go through the regular add flow (honouring the Add
    /// dialog preference unless `skipDialog`); other links are fetched by
    /// the result's plugin (nova2dl) and added with the defaults.
    func download(_ rows: [SearchResultRow], in tab: SearchTabModel, app: AppModel, skipDialog: Bool) {
        for row in rows {
            tab.visited.insert(row.id)
            let url = row.result.fileUrl
            if url.lowercased().hasPrefix("magnet:"), !skipDialog {
                app.add(.url(url: url))
                continue
            }
            let plugin = row.result.engineName
            Task {
                do {
                    try await client?.searchDownloadTorrent(url: url, plugin: plugin, params: .sessionDefaults)
                } catch {
                    alert = RSSAlert(title: String(localized: "Add torrent failed"), message: error.userMessage)
                }
            }
        }
    }

    /// Opens description pages; only http(s) links are allowed.
    func openDescriptions(_ rows: [SearchResultRow], app: AppModel) {
        var blocked: [String] = []
        var empty: [String] = []
        for row in rows {
            let link = row.result.descrLink.trimmingCharacters(in: .whitespaces)
            guard !link.isEmpty, let url = URL(string: link) else {
                empty.append(row.name)
                continue
            }
            guard RSSLinkPolicy.isWebURL(url) else {
                blocked.append(row.name)
                app.appendLocalLog("""
                    Blocked opening search result description page URL. URL pointing to local file might be malicious \
                    behaviour. Name: "\(row.name)". URL: "\(link)".
                    """)
                continue
            }
            NSWorkspace.shared.open(url)
        }
        if let first = blocked.first {
            alert = RSSAlert(title: "qBittorrent Neo", message: String(localized: """
                Blocked opening search result description page URL. The following result URL is pointing to local \
                file and it may be malicious behaviour:
                \(first)
                """) + (blocked.count > 1 ? "\n" + String(localized: "There are \(blocked.count - 1) more results with the same issue.") : ""))
        } else if let first = empty.first {
            alert = RSSAlert(title: "qBittorrent Neo", message: String(localized: "Entry \"\(first)\" has no description page URL provided.")
                + (empty.count > 1 ? "\n" + String(localized: "There are \(empty.count - 1) more entries with the same issue.") : ""))
        }
    }

    func copy(_ rows: [SearchResultRow], _ field: KeyPath<SearchResult, String>) {
        let text = rows.map { $0.result[keyPath: field] }.filter { !$0.isEmpty }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
