import Foundation

// Lua plugin calls of the C++ core (`core/src/api_plugins.cpp`).

extension QtCoreClient: PluginsClient {
    func pluginsStatus() -> PluginsStatus {
        bridge.value("pluginsStatus", fallback: .neoEmpty)
    }

    func installPlugin(path: String) async throws -> PluginInstallResult {
        try await bridge.callAsync("installPlugin", ["path": path])
    }

    func uninstallPlugin(id: String) async throws {
        try await bridge.callAsyncVoid("uninstallPlugin", ["id": id])
    }

    func setPluginEnabled(id: String, enabled: Bool) async throws {
        try await bridge.callAsyncVoid("setPluginEnabled", ["id": id, "enabled": enabled])
    }

    func invokePlugin(id: String) async throws {
        try await bridge.callAsyncVoid("invokePlugin", ["id": id])
    }
}
