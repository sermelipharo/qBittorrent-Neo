import Foundation

/// Properties panel pages (`PropertyTab` order).
enum PropertiesTab: Int, CaseIterable, Identifiable, Sendable {
    case general = 0
    case trackers = 1
    case peers = 2
    case httpSources = 3
    case content = 4
    case speed = 5

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .trackers: String(localized: "Trackers")
        case .peers: String(localized: "Peers")
        case .httpSources: String(localized: "HTTP Sources")
        case .content: String(localized: "Content")
        case .speed: String(localized: "Speed")
        }
    }

    var systemImage: String {
        switch self {
        case .general: "info.circle"
        case .trackers: "antenna.radiowaves.left.and.right"
        case .peers: "person.2"
        case .httpSources: "globe"
        case .content: "folder"
        case .speed: "chart.xyaxis.line"
        }
    }

    /// qBittorrent's Alt+letter shortcuts, used with ⌥ on macOS.
    var shortcutKey: Character {
        switch self {
        case .general: "g"
        case .trackers: "c"
        case .peers: "r"
        case .httpSources: "b"
        case .content: "z"
        case .speed: "d"
        }
    }
}
