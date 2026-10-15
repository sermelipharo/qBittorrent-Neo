import Foundation

/// The defaults store of the app's GUI-only settings. With `--profile <dir>`
/// they live in that profile (`<dir>/qBittorrent/config/gui-preferences.plist`),
/// like qBittorrent's custom profiles, which hold the GUI settings too; so a
/// second instance on another profile never changes the regular settings.
enum AppDefaults {
    /// `UserDefaults` is thread-safe (documented), just not marked `Sendable`.
    nonisolated(unsafe) static let store: UserDefaults = {
        let launch = LaunchOptions.current
        guard !launch.profileDirectory.isEmpty, !launch.usesDemoData else { return .standard }
        let config = URL(filePath: launch.profileDirectory, directoryHint: .isDirectory)
            .appending(path: "qBittorrent/config", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: config, withIntermediateDirectories: true)
        return UserDefaults(suiteName: config.appending(path: "gui-preferences").path(percentEncoded: false)) ?? .standard
    }()
}
