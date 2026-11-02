import Foundation
import Observation

/// Plugins window state (qBittorrent 5.3 `PluginsDialog`).
@Observable @MainActor
final class PluginsModel {
    private(set) var status = PluginsStatus(running: false, folder: "", plugins: [], problems: [])
    private(set) var plugins: [PluginInfo] = []
    var selection: Set<String> = []
    var sortOrder = [KeyPathComparator(\PluginInfo.id)] { didSet { plugins.sort(using: sortOrder) } }
    private(set) var busy = false
    var alert: RSSAlert?

    @ObservationIgnored private var client: (any PluginsClient)?

    /// The single selected plugin, shown in the details pane.
    var selectedPlugin: PluginInfo? {
        guard selection.count == 1, let id = selection.first else { return nil }
        return plugins.first { $0.id == id }
    }

    /// The selection contains an enabled plugin with an `invoke` function.
    var canInvoke: Bool {
        selectedPlugin.map { $0.invocable && $0.enabled } ?? false
    }

    func attach(_ client: (any CoreClient)?) async {
        guard let client = client as? any PluginsClient else { return }
        self.client = client
        await reload()
    }

    func reload() async {
        guard let client else { return }
        status = await CoreCall.run { client.pluginsStatus() }
        plugins = status.plugins.sorted(using: sortOrder)
        selection.formIntersection(plugins.map(\.id))
    }

    func setEnabled(_ ids: Set<String>, _ enabled: Bool) async {
        guard let client else { return }
        for id in ids {
            do {
                try await client.setPluginEnabled(id: id, enabled: enabled)
            } catch {
                alert = RSSAlert(title: String(localized: "Plugins"), message: error.userMessage)
            }
        }
        await reload()
    }

    func toggle(_ id: String) async {
        guard let plugin = plugins.first(where: { $0.id == id }) else { return }
        await setEnabled([id], !plugin.enabled)
    }

    /// Installs or updates plugins from local `.lua` files, one message per file.
    func install(_ paths: [String]) async {
        guard let client, !paths.isEmpty else { return }
        busy = true
        defer { busy = false }
        for path in paths {
            do {
                let result = try await client.installPlugin(path: path)
                let plugin = result.plugin
                alert = result.updated
                    ? RSSAlert(title: String(localized: "Plugin update"),
                               message: String(localized: "Plugin '\(plugin.id)' updated to version \(plugin.version)."))
                    : RSSAlert(title: String(localized: "Plugin install"), message: String(localized: "Plugin '\(plugin.id)' installed."))
            } catch QbtError.Conflict(let reason) {
                let id = URL(filePath: path).deletingPathExtension().lastPathComponent
                alert = RSSAlert(title: String(localized: "Plugin update"),
                                 message: String(localized: "Couldn't update plugin '\(id)' from file '\(path)'.\n\(reason)"))
            } catch {
                alert = RSSAlert(title: String(localized: "Plugin install"),
                                 message: String(localized: "Couldn't install plugin from file '\(path)'.\n\(error.userMessage)"))
            }
        }
        await reload()
    }

    func uninstall(_ ids: Set<String>) async {
        guard let client else { return }
        for id in ids.sorted() {
            do {
                try await client.uninstallPlugin(id: id)
                alert = RSSAlert(title: String(localized: "Plugin uninstall"), message: String(localized: "Plugin '\(id)' uninstalled."))
            } catch {
                alert = RSSAlert(title: String(localized: "Plugin uninstall"),
                                 message: String(localized: "Failed to uninstall plugin '\(id)'.\n\(error.userMessage)"))
            }
        }
        await reload()
    }

    func invoke(_ id: String) async {
        guard let client else { return }
        do {
            try await client.invokePlugin(id: id)
        } catch {
            alert = RSSAlert(title: String(localized: "Plugins"), message: error.userMessage)
        }
        await reload()
    }
}
