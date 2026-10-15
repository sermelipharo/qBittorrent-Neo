import Foundation

/// Compact description of one demo torrent; `DemoFactory` expands it into
/// full records (hashes, files, pieces, trackers, peers).
struct DemoSeed: Sendable {
    enum Layout: Sendable {
        /// One file named after the torrent.
        case single
        /// Relative paths (inside the root folder) with their share of the size.
        case files([(String, Double)])
    }

    var name: String
    var gib: Double
    var state: TorrentState
    var progress: Double
    var category: String = ""
    var tags: [String] = []
    var hosts: [String] = []
    var layout: Layout = .single
    var isPrivate = false
    var ratio = 0.0
    var addedDaysAgo = 3.0
    var comment = ""
    /// Nominal download / upload speed in KiB/s while active.
    var downKiB = 0.0
    var upKiB = 0.0
    var hybrid = false
    var error = ""
    var queuePosition: Int64 = 0
    var sequential = false
    var superSeeding = false
    var trackerWarning = false
    var trackerError = false
}
