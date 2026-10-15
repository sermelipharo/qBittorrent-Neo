import Foundation

/// Scene identifiers. The auxiliary windows (RSS, Search, Log, Creator,
/// Statistics, Cookies, About) are placeholders until their feature views land.
enum AppWindowID: String, CaseIterable, Sendable {
    case main
    case addTorrent = "add-torrent"
    case rss
    case search
    case log
    case creator
    case statistics
    case cookies
    case about

    var title: String {
        switch self {
        case .main: "qBittorrent Neo"
        case .addTorrent: String(localized: "Add New Torrent")
        case .rss: String(localized: "RSS Reader")
        case .search: String(localized: "Search")
        case .log: String(localized: "Execution Log")
        case .creator: String(localized: "Torrent Creator")
        case .statistics: String(localized: "Statistics")
        case .cookies: String(localized: "Manage Cookies")
        case .about: String(localized: "About qBittorrent Neo")
        }
    }

    var systemImage: String {
        switch self {
        case .main: Symbol.arrowDownCircle
        case .addTorrent: Symbol.docBadgePlus
        case .rss: Symbol.dotRadiowavesUpForward
        case .search: Symbol.magnifyingglass
        case .log: Symbol.textAlignleft
        case .creator: Symbol.wandAndStars
        case .statistics: Symbol.chartBar
        case .cookies: Symbol.listBulletRectangle
        case .about: Symbol.infoCircle
        }
    }
}
