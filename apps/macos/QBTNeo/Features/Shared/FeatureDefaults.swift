import Foundation

/// GUI-only settings of the feature windows that `GUIPreferences` doesn't
/// cover, stored in `UserDefaults` under qBittorrent's ini keys, plus a few
/// derived defaults.
enum FeatureDefaults {
    // Settings › Search
    static let storeSearchTabs = "Search/StoreOpenedSearchTabs"
    static let storeSearchResults = "Search/StoreOpenedSearchTabResults"
    static let searchHistoryLength = "Search/HistoryLength"
    static let searchHistory = "Search/History"
    static let searchUsesRegex = "SearchTab/UseRegexAsFilteringPattern"
    static let searchFilteringMode = "Search/FilteringMode"
    static let searchTabs = "Search/OpenedTabs"

    // RSS
    static let rssOpenedFolders = "GUI/RSSWidget/OpenedFolders"

    // Torrent Creator
    static let creatorPieceSize = "TorrentCreator/PieceSize"
    static let creatorPrivate = "TorrentCreator/PrivateTorrent"
    static let creatorStartSeeding = "TorrentCreator/StartSeeding"
    static let creatorIgnoreRatio = "TorrentCreator/IgnoreRatio"
    static let creatorFormat = "TorrentCreator/TorrentFormat"
    static let creatorOptimizeAlignment = "TorrentCreator/OptimizeAlignment"
    static let creatorPaddingLimit = "TorrentCreator/PaddedFileSizeLimit"
    static let creatorLastAddPath = "TorrentCreator/LastAddPath"
    static let creatorLastSavePath = "TorrentCreator/LastSavePath"
    static let creatorTrackers = "TorrentCreator/TrackerList"
    static let creatorWebSeeds = "TorrentCreator/WebSeedList"
    static let creatorComments = "TorrentCreator/Comments"
    static let creatorSource = "TorrentCreator/Source"

    // Settings › Downloads
    static let watchedFolderLastPath = "Preferences/Downloads/ScanDirsLastPath"

    /// `<profile>/data/logs`, the default execution log folder.
    static var defaultLogFolder: String {
        URL.applicationSupportDirectory.appending(path: "qBittorrent Neo/data/logs").path(percentEncoded: false)
    }

    /// History length clamped to 0…99 (default 50).
    static var searchHistoryLimit: Int {
        let stored = UserDefaults.standard.object(forKey: searchHistoryLength) as? Int ?? 50
        return min(max(stored, 0), 99)
    }
}
