import Foundation

/// Mutable state of one demo torrent (everything the properties tabs show).
struct DemoTorrent: Sendable {
    var info: TorrentInfo
    var files: [TorrentFile]
    var trackers: [TrackerEntry]
    var webSeeds: [String]
    var pieces: [UInt8]
    /// Nominal transfer rates while active, bytes/s.
    var baseDown: Double
    var baseUp: Double
    var seed: UInt64
    var dhtDisabled = false
    var pexDisabled = false
    var lsdDisabled = false
    /// Seconds left in a transient state (checking, moving) before it settles.
    var transientSeconds = 0.0
    var stateAfterTransient: TorrentState?

    var hash: String { info.hash }
    var isRunning: Bool { !info.state.isStopped }
}
