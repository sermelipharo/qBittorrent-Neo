import Foundation

/// Share limit values with qBittorrent's sentinels: ratio/times -2 = default
/// (category/global), -1 = unlimited; times in minutes.
struct ShareLimits: Equatable, Sendable {
    var ratio = -2.0
    var seedingMinutes: Int64 = -2
    var inactiveMinutes: Int64 = -2
    var action: ShareLimitAction = .default

    static let actions: [ShareLimitAction] = [.default, .stop, .remove, .removeWithContent, .enableSuperSeeding]

    static func title(of action: ShareLimitAction, fromCategory: Bool) -> String {
        switch action {
        case .default:
            if fromCategory { String(localized: "From category") } else { String(localized: "Default") }
        case .stop: String(localized: "Stop torrent")
        case .remove: String(localized: "Remove torrent")
        case .removeWithContent: String(localized: "Remove torrent and its content")
        case .enableSuperSeeding: String(localized: "Enable super seeding for torrent")
        }
    }
}
