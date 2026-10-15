import Foundation

/// Result groups of the Command Palette, with their section headers.
enum PaletteSection: String, Sendable {
    case recent
    case actions
    case torrents
    case filters
    case settings
    case categories
    case tags

    var title: String {
        switch self {
        case .recent: String(localized: "palette.section.recent", defaultValue: "Recent", comment: "Command Palette section header")
        case .actions: String(localized: "palette.section.actions", defaultValue: "Actions", comment: "Command Palette section header")
        case .torrents: String(localized: "Torrents")
        case .filters: String(localized: "palette.section.filters", defaultValue: "Filters", comment: "Command Palette section header")
        case .settings: String(localized: "Settings")
        case .categories: String(localized: "Categories")
        case .tags: String(localized: "Tags")
        }
    }

    /// At most this many rows per section while searching.
    var limit: Int {
        switch self {
        case .recent: 5
        case .actions: 8
        case .torrents: 8
        case .filters: 6
        case .settings: 6
        case .categories, .tags: 200
        }
    }
}
