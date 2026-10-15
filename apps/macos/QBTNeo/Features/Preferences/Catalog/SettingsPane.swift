import Foundation

/// The toolbar panes of the Settings window, ordered by task (docs/design/settings-ia.md §1).
/// Search & RSS is a segment of Transfers: with nine panes the Russian toolbar
/// overflowed (settings-ia.md §11.4).
enum SettingsPane: String, CaseIterable, Identifiable {
    case general
    case interface
    case transfers
    case speed
    case network
    case privacy
    case remote
    case advanced

    var id: Self { self }

    var title: String {
        switch self {
        // "General" and "Advanced" use pane-specific keys: their Russian (macOS
        // convention) differs from qBittorrent's translations of the same words.
        case .general: String(localized: "settings.pane.general", defaultValue: "General", comment: "Settings pane")
        case .interface: String(localized: "Interface")
        case .transfers: String(localized: "Transfers")
        case .speed: String(localized: "Speed")
        case .network: String(localized: "Network")
        case .privacy: String(localized: "Privacy")
        case .remote: String(localized: "Remote")
        case .advanced: String(localized: "settings.pane.advanced", defaultValue: "Advanced", comment: "Settings pane")
        }
    }

    /// Outline (default variant) symbol of the toolbar item.
    var symbol: String {
        switch self {
        case .general: Symbol.gearshape
        case .interface: Symbol.macwindow
        case .transfers: Symbol.arrowUpArrowDown
        case .speed: Symbol.speedometer
        case .network: Symbol.network
        case .privacy: Symbol.handRaised
        case .remote: Symbol.globe
        case .advanced: Symbol.gearshape2
        }
    }
}
