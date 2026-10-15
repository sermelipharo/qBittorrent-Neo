import Foundation

/// Every section of the Settings window, in pane order (docs/design/settings-ia.md §5).
/// Advanced sections come last in their pane, so turning advanced settings on
/// only appends content.
enum SettingsSection: String, CaseIterable, Identifiable {
    // General
    case startup, defaultApp, dockMenuBar, notifications, powerManagement, confirmations, updates, language
    // Interface
    case appearance, torrentList, doubleClick, sidebar, torrentDetails, statusBar, peersList, window
    // Transfers › Adding
    case saveLocation, addingTorrents, watchedFolders, duplicateTorrents, torrentFiles, extraTrackers
    // Transfers › Files
    case removingTorrents, filesOnDisk, categories, runProgram
    // Transfers › Seeding & Queue
    case seedingLimits, queue, checking
    // Speed
    case globalLimits, alternativeLimits, schedule, rateLimitSettings
    // Network
    case connectionStatus, listeningPort, findingPeers, protocolLimits
    // Privacy
    case encryption, vpn, proxy, ipFilter, appLock, downloadedFiles, i2p, protection
    // Remote
    case webUI, webUIAddress, signIn, https, accessRules, alternativeWebUI, webUISecurity, dynamicDNS
    // Transfers › Search & RSS
    case search, rss, smartEpisodeFilter
    // Advanced
    case showAdvanced, logs, dataRecovery, diskMemory, networkTuning, peersUploading, trackersAnnouncing, dht, safetyLimits,
         embeddedTracker

    var id: Self { self }

    /// Scroll/highlight anchor of the section.
    var anchor: String { "section." + rawValue }

    var pane: SettingsPane {
        switch self {
        case .startup, .defaultApp, .dockMenuBar, .notifications, .powerManagement, .confirmations, .updates, .language: .general
        case .appearance, .torrentList, .doubleClick, .sidebar, .torrentDetails, .statusBar, .peersList, .window: .interface
        case .saveLocation, .addingTorrents, .watchedFolders, .duplicateTorrents, .torrentFiles, .extraTrackers,
             .removingTorrents, .filesOnDisk, .categories, .runProgram, .seedingLimits, .queue, .checking,
             .search, .rss, .smartEpisodeFilter: .transfers
        case .globalLimits, .alternativeLimits, .schedule, .rateLimitSettings: .speed
        case .connectionStatus, .listeningPort, .findingPeers, .protocolLimits: .network
        case .encryption, .vpn, .proxy, .ipFilter, .appLock, .downloadedFiles, .i2p, .protection: .privacy
        case .webUI, .webUIAddress, .signIn, .https, .accessRules, .alternativeWebUI, .webUISecurity, .dynamicDNS: .remote
        case .showAdvanced, .logs, .dataRecovery, .diskMemory, .networkTuning, .peersUploading, .trackersAnnouncing, .dht,
             .safetyLimits, .embeddedTracker: .advanced
        }
    }

    var segment: TransfersSegment? {
        switch self {
        case .saveLocation, .addingTorrents, .watchedFolders, .duplicateTorrents, .torrentFiles, .extraTrackers: .adding
        case .removingTorrents, .filesOnDisk, .categories, .runProgram: .files
        case .seedingLimits, .queue, .checking: .seedingQueue
        case .search, .rss, .smartEpisodeFilter: .searchRSS
        default: nil
        }
    }

    /// The whole section is hidden while "Show advanced settings" is off.
    var isAdvanced: Bool {
        switch self {
        case .language, .peersList, .window, .duplicateTorrents, .torrentFiles, .extraTrackers, .filesOnDisk, .categories,
             .runProgram, .checking, .rateLimitSettings, .protocolLimits, .i2p, .protection, .accessRules, .alternativeWebUI,
             .webUISecurity, .dynamicDNS, .smartEpisodeFilter, .logs, .dataRecovery, .diskMemory, .networkTuning,
             .peersUploading, .trackersAnnouncing, .dht, .safetyLimits, .embeddedTracker:
            true
        default:
            false
        }
    }

    var title: String {
        switch self {
        case .startup: String(localized: "Startup")
        case .defaultApp: String(localized: "Default App")
        case .dockMenuBar: String(localized: "Dock & Menu Bar")
        case .notifications: String(localized: "Notifications")
        case .powerManagement: String(localized: "Power Management")
        case .confirmations: String(localized: "Confirmations")
        case .updates: String(localized: "Updates")
        case .language: String(localized: "Language")
        case .appearance: String(localized: "Appearance")
        case .torrentList: String(localized: "Torrent List")
        case .doubleClick: String(localized: "Action on double-click")
        case .sidebar: String(localized: "Sidebar")
        case .torrentDetails: String(localized: "Torrent Details")
        case .statusBar: String(localized: "Status Bar")
        case .peersList: String(localized: "Peers List")
        case .window: String(localized: "Window")
        case .saveLocation: String(localized: "Save Location")
        case .addingTorrents: String(localized: "When adding a torrent")
        case .watchedFolders: String(localized: "Watched Folders")
        case .duplicateTorrents: String(localized: "When adding a duplicate torrent")
        case .torrentFiles: String(localized: ".torrent Files")
        case .extraTrackers: String(localized: "Extra Trackers")
        case .removingTorrents: String(localized: "Removing Torrents")
        case .filesOnDisk: String(localized: "Files on Disk")
        case .categories: String(localized: "Categories & Automatic Mode")
        case .runProgram: String(localized: "Run a Program")
        case .seedingLimits: String(localized: "Seeding Limits")
        case .queue: String(localized: "Queue")
        case .checking: String(localized: "Checking")
        case .globalLimits: String(localized: "Global Rate Limits")
        case .alternativeLimits: String(localized: "Alternative Rate Limits")
        case .schedule: String(localized: "Schedule")
        case .rateLimitSettings: String(localized: "Rate Limits Settings")
        case .connectionStatus: String(localized: "Status")
        case .listeningPort: String(localized: "Listening Port")
        case .findingPeers: String(localized: "Finding Peers")
        case .protocolLimits: String(localized: "Protocol & Limits")
        case .encryption: String(localized: "Encryption & Anonymity")
        case .vpn: String(localized: "VPN Protection")
        case .proxy: String(localized: "Proxy Server")
        case .ipFilter: String(localized: "IP Filtering")
        case .appLock: String(localized: "App Lock")
        case .downloadedFiles: String(localized: "Downloaded Files")
        case .i2p: String(localized: "I2P (experimental)")
        case .protection: String(localized: "Protection")
        case .webUI: String(localized: "Web Interface")
        case .webUIAddress: String(localized: "Address")
        case .signIn: String(localized: "Sign-In")
        case .https: String(localized: "HTTPS")
        case .accessRules: String(localized: "Access Rules")
        case .alternativeWebUI: String(localized: "Alternative Web UI")
        case .webUISecurity: String(localized: "Security")
        case .dynamicDNS: String(localized: "Dynamic DNS")
        case .search: String(localized: "Search")
        case .rss: String(localized: "RSS")
        case .smartEpisodeFilter: String(localized: "RSS Smart Episode Filter")
        case .showAdvanced: String(localized: "settings.pane.advanced", defaultValue: "Advanced", comment: "Settings pane")
        case .logs: String(localized: "Logs & Diagnostics")
        case .dataRecovery: String(localized: "Data & Recovery")
        case .diskMemory: String(localized: "Disk & Memory")
        case .networkTuning: String(localized: "Network Tuning")
        case .peersUploading: String(localized: "Peers & Uploading")
        case .trackersAnnouncing: String(localized: "Trackers & Announcing")
        case .dht: String(localized: "DHT")
        case .safetyLimits: String(localized: "Safety Limits")
        case .embeddedTracker: String(localized: "Embedded Tracker")
        }
    }
}
