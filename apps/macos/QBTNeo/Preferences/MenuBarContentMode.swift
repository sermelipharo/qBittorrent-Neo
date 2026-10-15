import Foundation

/// What the menu bar item shows next to (or instead of) its icon.
enum MenuBarContentMode: Int, CaseIterable, Identifiable, Sendable {
    case iconOnly = 0
    case speed = 1
    case count = 2
    case speedAndCount = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .iconOnly: String(localized: "Icon only")
        case .speed: String(localized: "Transfer speed")
        case .count: String(localized: "Torrent count")
        case .speedAndCount: String(localized: "Speed and torrent count")
        }
    }

    var showsSpeed: Bool { self == .speed || self == .speedAndCount }
    var showsCount: Bool { self == .count || self == .speedAndCount }
}
