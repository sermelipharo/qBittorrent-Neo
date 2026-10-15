import Observation
import SwiftUI

/// Typed, observable access to every GUI-only preference. Values persist in
/// `UserDefaults` under the keys in `GUIPreferenceKey` (qBittorrent's ini
/// names). Views bind to these properties directly; the Settings window binds
/// the same instance, so changes apply live everywhere.
@Observable @MainActor
final class GUIPreferences {
    @ObservationIgnored private let defaults: UserDefaults

    // MARK: Interface / transfer list

    var colorScheme: ColorSchemePreference {
        didSet {
            set(colorScheme.rawValue, .colorScheme)
            applyAppearance()
        }
    }
    var alternatingRowColors: Bool { didSet { set(alternatingRowColors, .alternatingRowColors) } }
    var useTorrentStatesColors: Bool { didSet { set(useTorrentStatesColors, .useTorrentStatesColors) } }
    var progressBarFollowsTextColor: Bool { didSet { set(progressBarFollowsTextColor, .progressBarFollowsTextColor) } }
    var hideZeroValues: Bool { didSet { set(hideZeroValues, .hideZeroValues) } }
    var hideZeroMode: HideZeroMode { didSet { set(hideZeroMode.rawValue, .hideZeroComboValues) } }
    var doubleClickDownloading: DoubleClickAction { didSet { set(doubleClickDownloading.rawValue, .doubleClickDownloading) } }
    var doubleClickCompleted: DoubleClickAction { didSet { set(doubleClickCompleted.rawValue, .doubleClickCompleted) } }
    var hideZeroStatusFilters: Bool { didSet { set(hideZeroStatusFilters, .hideZeroStatusFilters) } }
    var separateTrackerStatusFilter: Bool { didSet { set(separateTrackerStatusFilter, .separateTrackerStatusFilter) } }
    var torrentContentDragEnabled: Bool { didSet { set(torrentContentDragEnabled, .torrentContentDragEnabled) } }
    var useRegexFilter: Bool { didSet { set(useRegexFilter, .useRegexFilter) } }

    // MARK: Desktop

    var startupWindowState: StartupWindowState { didSet { set(startupWindowState.rawValue, .startupWindowState) } }
    var confirmOnExit: Bool { didSet { set(confirmOnExit, .confirmOnExit) } }
    var confirmAutoExit: Bool { didSet { set(!confirmAutoExit, .dontConfirmAutoExit) } }
    var showSpeedInDock: Bool { didSet { set(showSpeedInDock, .showSpeedInDock) } }
    var showMenuBarIcon: Bool { didSet { set(showMenuBarIcon, .showMenuBarIcon) } }
    var menuBarContentMode: MenuBarContentMode { didSet { set(menuBarContentMode.rawValue, .menuBarContentMode) } }
    var menuBarShowsIcon: Bool { didSet { set(menuBarShowsIcon, .menuBarShowsIcon) } }
    var menuBarSpeedDirection: MenuBarSpeedDirection { didSet { set(menuBarSpeedDirection.rawValue, .menuBarSpeedDirection) } }
    var menuBarHidesZeroSpeed: Bool { didSet { set(menuBarHidesZeroSpeed, .menuBarHidesZeroSpeed) } }
    var menuBarCountStyle: MenuBarCountStyle { didSet { set(menuBarCountStyle.rawValue, .menuBarCountStyle) } }
    var preventSuspendWhenDownloading: Bool { didSet { set(preventSuspendWhenDownloading, .preventSuspendWhenDownloading) } }
    var preventSuspendWhenSeeding: Bool { didSet { set(preventSuspendWhenSeeding, .preventSuspendWhenSeeding) } }
    var statusBarFreeDiskSpace: Bool { didSet { set(statusBarFreeDiskSpace, .statusBarFreeDiskSpace) } }
    var checkForUpdates: Bool { didSet { set(checkForUpdates, .checkForUpdates) } }

    // MARK: Downloads

    var addTorrentDialogEnabled: Bool { didSet { set(addTorrentDialogEnabled, .addTorrentDialogEnabled) } }
    var addTorrentDialogTopLevel: Bool { didSet { set(addTorrentDialogTopLevel, .addTorrentDialogTopLevel) } }
    var confirmMergeTrackers: Bool { didSet { set(confirmMergeTrackers, .confirmMergeTrackers) } }
    var recursiveDownloadEnabled: Bool { didSet { set(!recursiveDownloadEnabled, .disableRecursiveDownload) } }

    // MARK: Advanced (GUI rows)

    var notificationsEnabled: Bool { didSet { set(notificationsEnabled, .notificationsEnabled) } }
    var notifyTorrentAdded: Bool { didSet { set(notifyTorrentAdded, .notifyTorrentAdded) } }
    var confirmRemoveAllTags: Bool { didSet { set(confirmRemoveAllTags, .confirmRemoveAllTags) } }
    var confirmRemoveTrackerFromAllTorrents: Bool {
        didSet { set(confirmRemoveTrackerFromAllTorrents, .confirmRemoveTrackerFromAllTorrents) }
    }
    var downloadTrackerFavicon: Bool { didSet { set(downloadTrackerFavicon, .downloadTrackerFavicon) } }
    /// Clamped to 0...99.
    var savePathHistoryLength: Int {
        didSet {
            let clamped = min(max(savePathHistoryLength, 0), 99)
            if clamped != savePathHistoryLength { savePathHistoryLength = clamped; return }
            set(savePathHistoryLength, .savePathHistoryLength)
            savePathHistory = Array(savePathHistory.prefix(clamped))
            downloadPathHistory = Array(downloadPathHistory.prefix(clamped))
        }
    }
    var speedGraphsEnabled: Bool { didSet { set(speedGraphsEnabled, .speedGraphsEnabled) } }

    // MARK: Main window

    var statusBarDisplayed: Bool { didSet { set(statusBarDisplayed, .statusBarDisplayed) } }
    var filtersSidebarVisible: Bool { didSet { set(filtersSidebarVisible, .filtersSidebarVisible) } }
    var speedInTitleBar: Bool { didSet { set(speedInTitleBar, .speedInTitleBar) } }
    var rssEnabled: Bool { didSet { set(rssEnabled, .rssEnabled) } }
    var searchEnabled: Bool { didSet { set(searchEnabled, .searchEnabled) } }
    var logEnabled: Bool { didSet { set(logEnabled, .logEnabled) } }
    /// `Log::MsgTypes` flags (NORMAL 0x1, INFO 0x2, WARNING 0x4, CRITICAL 0x8; -1 = all).
    var logTypes: Int { didSet { set(logTypes, .logTypes) } }
    var completionAction: CompletionAction { didSet { storeCompletionAction() } }
    var selectedStatusFilterIndex: Int { didSet { set(selectedStatusFilterIndex, .selectedStatusFilter) } }
    var statusSectionExpanded: Bool { didSet { set(statusSectionExpanded, .statusSectionExpanded) } }
    var categorySectionExpanded: Bool { didSet { set(categorySectionExpanded, .categorySectionExpanded) } }
    var tagSectionExpanded: Bool { didSet { set(tagSectionExpanded, .tagSectionExpanded) } }
    var trackerStatusSectionExpanded: Bool { didSet { set(trackerStatusSectionExpanded, .trackerStatusSectionExpanded) } }
    var trackerSectionExpanded: Bool { didSet { set(trackerSectionExpanded, .trackerSectionExpanded) } }
    var lastOpenDirectory: String { didSet { set(lastOpenDirectory, .lastOpenDirectory) } }

    // MARK: Properties panel

    var propertiesVisible: Bool { didSet { set(propertiesVisible, .propertiesVisible) } }
    var propertiesTab: PropertiesTab { didSet { set(propertiesTab.rawValue, .propertiesCurrentTab) } }
    var propertiesHeight: Double { didSet { set(propertiesHeight, .propertiesHeight) } }
    var contentFilterPatternFormat: FilterPatternFormat {
        didSet { set(contentFilterPatternFormat.rawValue, .contentFilterPatternFormat) }
    }
    var speedGraphPeriod: SpeedGraphPeriod { didSet { set(speedGraphPeriod.rawValue, .speedGraphPeriod) } }
    var speedGraphSeries: Set<SpeedGraphSeries> {
        didSet { set(speedGraphSeries.map(\.rawValue).sorted(), .speedGraphSeries) }
    }

    // MARK: Add New Torrent dialog

    var rememberLastSavePath: Bool { didSet { set(rememberLastSavePath, .rememberLastSavePath) } }
    var defaultCategory: String { didSet { set(defaultCategory, .defaultCategory) } }
    var savePathHistory: [String] { didSet { set(savePathHistory, .savePathHistory) } }
    var downloadPathHistory: [String] { didSet { set(downloadPathHistory, .downloadPathHistory) } }
    var addTorrentFilterPatternFormat: FilterPatternFormat {
        didSet { set(addTorrentFilterPatternFormat.rawValue, .addTorrentFilterPatternFormat) }
    }
    var trackersListURL: String { didSet { set(trackersListURL, .trackersListURL) } }

    /// Applies the theme to the whole app (every window, sheet, menu and alert),
    /// not just one scene as `preferredColorScheme` would.
    func applyAppearance() {
        NSApp?.appearance = colorScheme.appearance
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let read = Reader(defaults: defaults)
        colorScheme = ColorSchemePreference(rawValue: read.int(.colorScheme, 0)) ?? .system
        alternatingRowColors = read.bool(.alternatingRowColors, true)
        useTorrentStatesColors = read.bool(.useTorrentStatesColors, true)
        progressBarFollowsTextColor = read.bool(.progressBarFollowsTextColor, false)
        hideZeroValues = read.bool(.hideZeroValues, false)
        hideZeroMode = HideZeroMode(rawValue: read.int(.hideZeroComboValues, 0)) ?? .always
        doubleClickDownloading = DoubleClickAction(rawValue: read.int(.doubleClickDownloading, 0)) ?? .toggleStop
        doubleClickCompleted = DoubleClickAction(rawValue: read.int(.doubleClickCompleted, 1)) ?? .openDestination
        hideZeroStatusFilters = read.bool(.hideZeroStatusFilters, false)
        separateTrackerStatusFilter = read.bool(.separateTrackerStatusFilter, false)
        torrentContentDragEnabled = read.bool(.torrentContentDragEnabled, false)
        useRegexFilter = read.bool(.useRegexFilter, false)

        startupWindowState = StartupWindowState(rawValue: read.int(.startupWindowState, 0)) ?? .normal
        confirmOnExit = read.bool(.confirmOnExit, true)
        confirmAutoExit = !read.bool(.dontConfirmAutoExit, false)
        showSpeedInDock = read.bool(.showSpeedInDock, true)
        showMenuBarIcon = read.bool(.showMenuBarIcon, true)
        menuBarContentMode = MenuBarContentMode(rawValue: read.int(.menuBarContentMode, 0)) ?? .iconOnly
        menuBarShowsIcon = read.bool(.menuBarShowsIcon, true)
        menuBarSpeedDirection = MenuBarSpeedDirection(rawValue: read.int(.menuBarSpeedDirection, 0)) ?? .both
        menuBarHidesZeroSpeed = read.bool(.menuBarHidesZeroSpeed, false)
        menuBarCountStyle = MenuBarCountStyle(rawValue: read.int(.menuBarCountStyle, 0)) ?? .activeOfTotal
        preventSuspendWhenDownloading = read.bool(.preventSuspendWhenDownloading, false)
        preventSuspendWhenSeeding = read.bool(.preventSuspendWhenSeeding, false)
        statusBarFreeDiskSpace = read.bool(.statusBarFreeDiskSpace, false)
        checkForUpdates = read.bool(.checkForUpdates, true)

        addTorrentDialogEnabled = read.bool(.addTorrentDialogEnabled, true)
        addTorrentDialogTopLevel = read.bool(.addTorrentDialogTopLevel, true)
        confirmMergeTrackers = read.bool(.confirmMergeTrackers, true)
        recursiveDownloadEnabled = !read.bool(.disableRecursiveDownload, false)

        notificationsEnabled = read.bool(.notificationsEnabled, true)
        notifyTorrentAdded = read.bool(.notifyTorrentAdded, false)
        confirmRemoveAllTags = read.bool(.confirmRemoveAllTags, true)
        confirmRemoveTrackerFromAllTorrents = read.bool(.confirmRemoveTrackerFromAllTorrents, true)
        downloadTrackerFavicon = read.bool(.downloadTrackerFavicon, false)
        savePathHistoryLength = min(max(read.int(.savePathHistoryLength, 8), 0), 99)
        speedGraphsEnabled = read.bool(.speedGraphsEnabled, true)

        statusBarDisplayed = read.bool(.statusBarDisplayed, true)
        filtersSidebarVisible = read.bool(.filtersSidebarVisible, true)
        speedInTitleBar = read.bool(.speedInTitleBar, false)
        rssEnabled = read.bool(.rssEnabled, false)
        searchEnabled = read.bool(.searchEnabled, false)
        logEnabled = read.bool(.logEnabled, false)
        logTypes = read.int(.logTypes, -1)
        completionAction = Self.loadCompletionAction(read)
        selectedStatusFilterIndex = read.int(.selectedStatusFilter, 0)
        statusSectionExpanded = read.bool(.statusSectionExpanded, true)
        categorySectionExpanded = read.bool(.categorySectionExpanded, true)
        tagSectionExpanded = read.bool(.tagSectionExpanded, true)
        trackerStatusSectionExpanded = read.bool(.trackerStatusSectionExpanded, true)
        trackerSectionExpanded = read.bool(.trackerSectionExpanded, true)
        lastOpenDirectory = read.string(.lastOpenDirectory, NSHomeDirectory())

        propertiesVisible = read.bool(.propertiesVisible, true)
        propertiesTab = PropertiesTab(rawValue: read.int(.propertiesCurrentTab, 0)) ?? .general
        propertiesHeight = read.double(.propertiesHeight, 0)
        contentFilterPatternFormat = FilterPatternFormat(rawValue: read.int(.contentFilterPatternFormat, 1)) ?? .wildcards
        speedGraphPeriod = SpeedGraphPeriod(rawValue: read.int(.speedGraphPeriod, 1)) ?? .minutes5
        if let ids = defaults.array(forKey: GUIPreferenceKey.speedGraphSeries.rawValue) as? [Int] {
            speedGraphSeries = Set(ids.compactMap(SpeedGraphSeries.init(rawValue:)))
        } else {
            speedGraphSeries = SpeedGraphSeries.defaultEnabled
        }

        rememberLastSavePath = read.bool(.rememberLastSavePath, false)
        defaultCategory = read.string(.defaultCategory, "")
        savePathHistory = read.strings(.savePathHistory)
        downloadPathHistory = read.strings(.downloadPathHistory)
        addTorrentFilterPatternFormat = FilterPatternFormat(rawValue: read.int(.addTorrentFilterPatternFormat, 1)) ?? .wildcards
        trackersListURL = read.string(.trackersListURL, "")
    }

    /// Split view column visibility bound to "Filters Sidebar".
    var sidebarVisibility: NavigationSplitViewVisibility {
        get { filtersSidebarVisible ? .all : .detailOnly }
        set { filtersSidebarVisible = newValue != .detailOnly }
    }

    /// Whether zero/∞ cells are blanked for a torrent in `isStoppedDownloading` state.
    func hidesZeroValues(isStoppedDownloading: Bool) -> Bool {
        hideZeroValues && (hideZeroMode == .always || isStoppedDownloading)
    }

    /// Moves `path` to the front of an MRU history, trimmed to the configured length.
    func remember(savePath path: String) {
        savePathHistory = Self.mru(savePathHistory, adding: path, limit: savePathHistoryLength)
    }

    func remember(downloadPath path: String) {
        downloadPathHistory = Self.mru(downloadPathHistory, adding: path, limit: savePathHistoryLength)
    }

    /// Execution log type filter flag (NORMAL 0x1, INFO 0x2, WARNING 0x4, CRITICAL 0x8).
    subscript(logType flag: Int) -> Bool {
        get { logTypes & flag != 0 }
        set { logTypes = newValue ? (logTypes | flag) : (logTypes & ~flag) }
    }

    private static func mru(_ list: [String], adding path: String, limit: Int) -> [String] {
        guard !path.isEmpty else { return list }
        var result = list.filter { $0 != path }
        result.insert(path, at: 0)
        return Array(result.prefix(limit))
    }

    private func set(_ value: Any, _ key: GUIPreferenceKey) {
        defaults.set(value, forKey: key.rawValue)
    }

    private func storeCompletionAction() {
        set(completionAction == .exitApp, .autoExitOnCompletion)
        set(completionAction == .suspend, .autoSuspendOnCompletion)
        set(completionAction == .reboot, .autoRebootOnCompletion)
        set(completionAction == .shutdown, .autoShutdownOnCompletion)
    }

    private static func loadCompletionAction(_ read: Reader) -> CompletionAction {
        if read.bool(.autoSuspendOnCompletion, false) { return .suspend }
        if read.bool(.autoShutdownOnCompletion, false) { return .shutdown }
        if read.bool(.autoRebootOnCompletion, false) { return .reboot }
        if read.bool(.autoExitOnCompletion, false) { return .exitApp }
        return .doNothing
    }

    /// Typed reads with defaults (missing keys fall back to qBittorrent's defaults).
    private struct Reader {
        let defaults: UserDefaults

        func bool(_ key: GUIPreferenceKey, _ fallback: Bool) -> Bool {
            defaults.object(forKey: key.rawValue) as? Bool ?? fallback
        }

        func int(_ key: GUIPreferenceKey, _ fallback: Int) -> Int {
            defaults.object(forKey: key.rawValue) as? Int ?? fallback
        }

        func double(_ key: GUIPreferenceKey, _ fallback: Double) -> Double {
            defaults.object(forKey: key.rawValue) as? Double ?? fallback
        }

        func string(_ key: GUIPreferenceKey, _ fallback: String) -> String {
            defaults.string(forKey: key.rawValue) ?? fallback
        }

        func strings(_ key: GUIPreferenceKey) -> [String] {
            defaults.stringArray(forKey: key.rawValue) ?? []
        }
    }
}
