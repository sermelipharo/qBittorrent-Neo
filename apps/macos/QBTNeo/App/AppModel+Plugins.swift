import Foundation

extension AppModel {
    /// Reloads the enabled plugins with an `invoke` function for the Plugins
    /// menu (at start and on `pluginsChanged`), so the menu never calls the core.
    func refreshInvocablePlugins() {
        guard let client = client as? any PluginsClient else { return }
        Task {
            let status = await CoreCall.run { client.pluginsStatus() }
            invocablePlugins = status.plugins.filter { $0.invocable && $0.enabled }.sorted { $0.name < $1.name }
        }
    }

    /// Plugins menu: calls the plugin's `invoke` function. Failures are in
    /// the execution log, as in qBittorrent.
    func invokePlugin(_ id: String) {
        guard let client = client as? any PluginsClient else { return }
        Task { try? await client.invokePlugin(id: id) }
    }
}
