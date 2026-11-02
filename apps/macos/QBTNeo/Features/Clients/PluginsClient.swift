import Foundation

/// Lua plugin calls of the core (`api_plugins.cpp`, qBittorrent 5.3's
/// `PluginsEngine`). Same signatures as the sibling project's facade.
protocol PluginsClient: AnyObject, Sendable {
    func pluginsStatus() -> PluginsStatus
    func installPlugin(path: String) async throws -> PluginInstallResult
    func uninstallPlugin(id: String) async throws
    func setPluginEnabled(id: String, enabled: Bool) async throws
    func invokePlugin(id: String) async throws
}
