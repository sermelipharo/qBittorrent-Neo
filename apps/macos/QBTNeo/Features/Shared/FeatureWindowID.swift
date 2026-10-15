import Foundation

/// Scene identifiers of the feature dialogs that can be opened from several
/// places (Settings and their parent windows).
enum FeatureWindowID: String {
    case rssDownloader = "rss-downloader"
    case searchPlugins = "search-plugins"

    var title: String {
        switch self {
        case .rssDownloader: String(localized: "RSS Downloader")
        case .searchPlugins: String(localized: "Search plugins")
        }
    }
}
