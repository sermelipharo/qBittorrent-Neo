import Foundation

/// Command-line switches:
/// * `--demo`: use the in-process sample session instead of the qBittorrent core.
/// * `--demo-large`: demo with 2,000 torrents (performance testing).
/// * `--snapshot <dir>`: render key windows to PNG files with demo data, then exit.
/// * `--snapshot-scale <n>`: render snapshots at n pixels per point (default:
///   the screen's backing scale), e.g. 4 for close-ups on a web page.
/// * `--snapshot-active`: draw every snapshot window as the active window.
/// * `--snapshot-clear`: leave the window background transparent, so the
///   areas that would show a material (sidebar, toolbar) can be composed over
///   another background.
/// * `--profile <dir>`: use another profile folder for the real core.
/// * `--assume-visible`: refresh as if the main window were always visible
///   (idle CPU measurements of a window started in the background).
struct LaunchOptions: Sendable {
    var demo = false
    var demoLarge = false
    var snapshotDirectory: URL?
    var snapshotScale: CGFloat?
    var snapshotActive = false
    var snapshotClear = false
    var profileDirectory = ""
    var assumesVisibleWindow = false

    static let current = Self(arguments: CommandLine.arguments)

    init(arguments: [String]) {
        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--demo": demo = true
            case "--demo-large": demoLarge = true
            case "--snapshot":
                if let path = iterator.next() { snapshotDirectory = URL(filePath: path, directoryHint: .isDirectory) }
            case "--snapshot-scale":
                if let text = iterator.next(), let value = Double(text), (1...8).contains(value) { snapshotScale = value }
            case "--snapshot-active": snapshotActive = true
            case "--snapshot-clear": snapshotClear = true
            case "--profile":
                profileDirectory = iterator.next() ?? ""
            case "--assume-visible": assumesVisibleWindow = true
            default: break
            }
        }
    }

    var isSnapshot: Bool { snapshotDirectory != nil }
    var usesDemoData: Bool { demo || demoLarge || isSnapshot }
}
