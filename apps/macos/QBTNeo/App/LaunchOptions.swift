import Foundation

/// Command-line switches:
/// * `--demo`: use the in-process sample session instead of the qBittorrent core.
/// * `--demo-large`: demo with 2,000 torrents (performance testing).
/// * `--snapshot <dir>`: render key windows to PNG files with demo data, then exit.
/// * `--profile <dir>`: use another profile folder for the real core.
struct LaunchOptions: Sendable {
    var demo = false
    var demoLarge = false
    var snapshotDirectory: URL?
    var profileDirectory = ""

    static let current = Self(arguments: CommandLine.arguments)

    init(arguments: [String]) {
        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--demo": demo = true
            case "--demo-large": demoLarge = true
            case "--snapshot":
                if let path = iterator.next() { snapshotDirectory = URL(filePath: path, directoryHint: .isDirectory) }
            case "--profile":
                profileDirectory = iterator.next() ?? ""
            default: break
            }
        }
    }

    var isSnapshot: Bool { snapshotDirectory != nil }
    var usesDemoData: Bool { demo || demoLarge || isSnapshot }
}
