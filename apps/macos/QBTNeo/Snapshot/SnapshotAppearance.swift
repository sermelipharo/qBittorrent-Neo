import AppKit

/// Appearances rendered by snapshot mode.
enum SnapshotAppearance: String, CaseIterable {
    case light
    case dark

    var name: NSAppearance.Name {
        switch self {
        case .light: .aqua
        case .dark: .darkAqua
        }
    }
}

extension PropertiesTab {
    var snapshotName: String {
        switch self {
        case .general: "general"
        case .trackers: "trackers"
        case .peers: "peers"
        case .httpSources: "http"
        case .content: "content"
        case .speed: "speed"
        }
    }
}
