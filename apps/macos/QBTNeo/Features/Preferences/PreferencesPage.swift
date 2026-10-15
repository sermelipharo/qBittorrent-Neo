import SwiftUI

/// Pages of the Settings window, in qBittorrent's order.
enum PreferencesPage: Int, CaseIterable, Identifiable {
    case behavior
    case downloads
    case connection
    case speed
    case bittorrent
    case search
    case rss
    case webUI
    case advanced

    var id: Self { self }

    var title: String {
        switch self {
        case .behavior: String(localized: "Behavior")
        case .downloads: String(localized: "Downloads")
        case .connection: String(localized: "Connection")
        case .speed: String(localized: "Speed")
        case .bittorrent: String(localized: "BitTorrent")
        case .search: String(localized: "Search")
        case .rss: String(localized: "RSS")
        case .webUI: String(localized: "WebUI")
        case .advanced: String(localized: "Advanced")
        }
    }

    var systemImage: String {
        switch self {
        case .behavior: "macwindow"
        case .downloads: "arrow.down"
        case .connection: "network"
        case .speed: "speedometer"
        case .bittorrent: "point.3.connected.trianglepath.dotted"
        case .search: "magnifyingglass"
        case .rss: "dot.radiowaves.up.forward"
        case .webUI: "globe"
        case .advanced: "gearshape.2"
        }
    }

    var tint: Color {
        switch self {
        case .behavior: .gray
        case .downloads: .blue
        case .connection: .teal
        case .speed: .orange
        case .bittorrent: .green
        case .search: .indigo
        case .rss: .orange
        case .webUI: .cyan
        case .advanced: .gray
        }
    }
}
