import AppKit
import SwiftUI

/// Renders the feature windows (Preferences pages, RSS, Search, Log,
/// Creator, Statistics, About, Cookies) with demo data in `--snapshot` mode.
/// `--snapshot-only <name,…>` limits the run to windows whose name starts
/// with one of the given prefixes.
@MainActor
struct FeatureSnapshots {
    let directory: URL
    let launch: LaunchOptions

    func run() async {
        DemoFeatureStore.shared.isInstant.withLock { $0 = true }
        let defaults = UserDefaults(suiteName: "mk.lex.qbtneo.snapshots") ?? .standard
        let model = AppModel(launch: launch, gui: GUIPreferences(defaults: defaults))
        model.attach(DemoClient(large: false, animated: false))
        await model.refresh()
        let renderer = OffscreenWindowRenderer(directory: directory)
        for entry in FeatureSnapshotCatalog.entries where isWanted(entry.name) {
            await renderer.render(entry.name, title: entry.title, size: entry.size) {
                entry.view(model)
                    .environment(model)
                    .environment(model.gui)
            }
        }
        model.stopRefreshing()
    }

    /// `--snapshot-only` was given: render only the matching feature windows.
    static var isFiltered: Bool { filter != nil }

    private static var filter: [Substring]? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--snapshot-only"), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1].split(separator: ",")
    }

    private func isWanted(_ name: String) -> Bool {
        guard let filter = Self.filter else { return true }
        return filter.contains { name.hasPrefix($0) }
    }
}
