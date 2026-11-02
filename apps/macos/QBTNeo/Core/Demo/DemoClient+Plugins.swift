import Foundation

extension DemoClient: PluginsClient {
    private var store: DemoFeatureStore { .shared }

    func pluginsStatus() -> PluginsStatus {
        store.plugins.withLock { $0.status }
    }

    func installPlugin(path: String) async throws -> PluginInstallResult {
        let url = URL(filePath: path)
        guard url.pathExtension == "lua" else {
            throw QbtError.InvalidArgument(message: "'\(url.lastPathComponent)' is not a plugin file name (expected <name>.lua).")
        }
        let id = url.deletingPathExtension().lastPathComponent
        return store.plugins.withLock { state in
            let previous = state.plugins.first { $0.id == id }
            state.plugins.removeAll { $0.id == id }
            let info = PluginInfo(
                id: id, name: id, version: "1.0", author: "", description: "", invocable: false, enabled: previous?.enabled ?? false,
                handlers: [], filePath: path, fileSize: 512, sha256: String(repeating: "0", count: 64),
                programsRun: 0, mailsSent: 0, failures: 0, lastError: ""
            )
            state.plugins.append(info)
            return PluginInstallResult(plugin: info, updated: previous != nil, previousVersion: previous?.version ?? "")
        }
    }

    func uninstallPlugin(id: String) async throws {
        store.plugins.withLock { $0.plugins.removeAll { $0.id == id } }
    }

    func setPluginEnabled(id: String, enabled: Bool) async throws {
        store.plugins.withLock { state in
            for index in state.plugins.indices where state.plugins[index].id == id {
                state.plugins[index].enabled = enabled
            }
        }
    }

    func invokePlugin(id: String) async throws {}
}
