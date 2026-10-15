import Foundation

/// Trackers filter rows. The announce-status rows live here unless the
/// separate "Tracker status" section is enabled.
enum TrackerFilter: Hashable, Sendable {
    case all
    case trackerless
    case trackerError
    case otherError
    case warning
    case host(String)
}
