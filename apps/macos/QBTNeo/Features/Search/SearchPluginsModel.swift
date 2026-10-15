import Foundation
import Observation

/// Search plugins dialog state (features.md §3.23, §5.8.2).
@Observable @MainActor
final class SearchPluginsModel {
    private(set) var plugins: [SearchPlugin] = []
    var selection: Set<String> = []
    var sortOrder = [KeyPathComparator(\SearchPlugin.fullName)] { didSet { plugins.sort(using: sortOrder) } }
    private(set) var busy = false
    var alert: RSSAlert?

    @ObservationIgnored private var client: (any SearchClient)?

    func attach(_ client: (any CoreClient)?) async {
        guard let client = client as? any SearchClient else { return }
        self.client = client
        await reload()
    }

    func reload() async {
        guard let client else { return }
        plugins = await CoreCall.run { client.searchPlugins() }.sorted(using: sortOrder)
    }

    func setEnabled(_ names: Set<String>, _ enabled: Bool) {
        do {
            try client?.searchEnablePlugins(names: Array(names), enable: enabled)
        } catch {
            alert = RSSAlert(title: String(localized: "Search plugins"), message: error.userMessage)
        }
        Task { await reload() }
    }

    func toggle(_ name: String) {
        guard let plugin = plugins.first(where: { $0.name == name }) else { return }
        setEnabled([name], !plugin.enabled)
    }

    func uninstall(_ names: Set<String>) async {
        do {
            try client?.searchUninstallPlugins(names: Array(names))
            await reload()
            let remaining = plugins.filter { names.contains($0.name) }
            alert = remaining.isEmpty
                ? RSSAlert(title: String(localized: "Uninstall success"), message: String(localized: "All selected plugins were uninstalled successfully"))
                : RSSAlert(title: String(localized: "Uninstall warning"), message: String(localized: """
                    Some plugins could not be uninstalled because they are included in qBittorrent Neo. Only the ones you \
                    added yourself can be uninstalled.
                    Those plugins were disabled.
                    """))
        } catch {
            alert = RSSAlert(title: String(localized: "Uninstall warning"), message: error.userMessage)
        }
    }

    /// Installs plugins from `.py` URLs or local paths.
    func install(_ sources: [String]) async {
        guard let client, !sources.isEmpty else { return }
        busy = true
        defer { busy = false }
        do {
            try await client.searchInstallPlugins(sources: sources)
            await reload()
            let names = sources.map { URL(string: $0)?.deletingPathExtension().lastPathComponent ?? $0 }
            alert = RSSAlert(title: String(localized: "Search plugin update"),
                             message: String(localized: "Plugins installed or updated: \(names.sorted().formatted())"))
        } catch {
            alert = RSSAlert(title: String(localized: "Search plugin install"),
                             message: String(localized: "Couldn't install \"\(sources.formatted())\" search engine plugin. \(error.userMessage)"))
        }
    }

    func checkForUpdates() async {
        guard let client else { return }
        busy = true
        defer { busy = false }
        let before = plugins.map(\.version)
        do {
            try await client.searchUpdatePlugins()
            await reload()
            if plugins.map(\.version) == before {
                alert = RSSAlert(title: String(localized: "Search plugin update"), message: String(localized: "All your plugins are already up to date."))
            }
        } catch {
            alert = RSSAlert(title: String(localized: "Search plugin update"),
                             message: String(localized: "Sorry, couldn't check for plugin updates. \(error.userMessage)"))
        }
    }
}
