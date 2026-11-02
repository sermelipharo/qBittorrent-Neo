import Foundation

/// Demo plugins: qBittorrent 5.3's example plugins, as its engine lists them
/// (ID, name, version, invocable, enabled and the file; no handler list or
/// activity counters).
struct DemoPluginsState {
    static let folder = "~/Library/Application Support/mk.lex.qbittorrentneo/qBittorrent/data/plugins"

    var plugins: [PluginInfo] = [
        Self.plugin("EmailNotifier", "Email Notifier Example"),
        Self.plugin("EventHandler", "Event Handler Example", enabled: false),
        Self.plugin("Invocable", "Invocable Example", invocable: true),
        Self.plugin("RunExternalProgram", "Run External Program Example"),
    ]

    var status: PluginsStatus {
        PluginsStatus(running: true, folder: Self.folder, plugins: plugins.sorted { $0.id < $1.id }, problems: [])
    }

    private static func plugin(_ id: String, _ name: String, invocable: Bool = false, enabled: Bool = true) -> PluginInfo {
        PluginInfo(
            id: id, name: name, version: "0.1", author: "", description: "", invocable: invocable, enabled: enabled,
            handlers: [], filePath: "\(folder)/\(id).lua",
            fileSize: Int64(200 + id.count * 37), sha256: String(repeating: "5f3a9c", count: 10) + "0b1e",
            programsRun: 0, mailsSent: 0, failures: 0, lastError: ""
        )
    }
}
