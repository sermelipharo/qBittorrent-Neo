import SwiftUI

/// Commands of the File, View, Tools and Help menus.
extension CommandRegistry {
    static var appCommands: [AppCommand] {
        fileCommands + viewCommands + detailsCommands + windowCommands
    }

    private static var fileCommands: [AppCommand] {
        [
            AppCommand(.addTorrentFile, String(localized: "Add Torrent File…"), symbol: Symbol.docBadgePlus, shortcut: CommandShortcut("o"),
                       keywords: words(String(localized: "palette.keywords.addFile", defaultValue: "open, import",
                                              comment: "Command Palette search words, comma-separated"))) {
                $0.model.fileImport = .torrentFiles
            },
            AppCommand(.addTorrentLink, String(localized: "Add Torrent Link…"), symbol: Symbol.linkBadgePlus,
                       shortcut: CommandShortcut("o", [.command, .shift]),
                       keywords: words(String(localized: "palette.keywords.addLink", defaultValue: "magnet, url, download",
                                              comment: "Command Palette search words, comma-separated"))) {
                $0.model.sheet = .addLinks(initialText: AppModel.clipboardLinks())
            },
        ]
    }

    private static var viewCommands: [AppCommand] {
        [
            AppCommand(.alternativeSpeedLimits, String(localized: "Alternative Speed Limits"), symbol: Symbol.tortoise,
                       shortcut: CommandShortcut("t", [.command, .shift]),
                       keywords: words(String(localized: "palette.keywords.altSpeed", defaultValue: "turtle, slow, throttle",
                                              comment: "Command Palette search words, comma-separated"))) { $0.model.toggleAltSpeedLimits() }
                .state { $0.alternativeSpeedLimits },
            AppCommand(.globalSpeedLimits, String(localized: "Global Speed Limits…"), symbol: Symbol.speedometer,
                       keywords: words(String(localized: "palette.keywords.speedLimits", defaultValue: "rate, bandwidth, throttle",
                                              comment: "Command Palette search words, comma-separated"))) {
                $0.model.sheet = .speedLimits
            },
            AppCommand(.resetFilters, String(localized: "Reset Filters"), symbol: Symbol.line3HorizontalDecreaseCircle,
                       keywords: words(String(localized: "palette.keywords.resetFilters", defaultValue: "clear, show all",
                                              comment: "Command Palette search words, comma-separated"))) { $0.model.list.resetAllFilters() }
                .available { $0.model.list.isFiltering },
            AppCommand(.toggleFiltersSidebar, String(localized: "Filters Sidebar"), symbol: Symbol.sidebarLeft,
                       shortcut: CommandShortcut("s", [.control, .command])) { $0.model.gui.filtersSidebarVisible.toggle() }
                .state { $0.gui.filtersSidebarVisible },
            AppCommand(.toggleStatusBar, String(localized: "Status Bar"), symbol: Symbol.menubarRectangle) { $0.model.gui.statusBarDisplayed.toggle() }
                .state { $0.gui.statusBarDisplayed },
            AppCommand(.toggleSpeedInTitle, String(localized: "Speed in Title Bar"), symbol: Symbol.arrowUpArrowDown) { $0.model.gui.speedInTitleBar.toggle() }
                .state { $0.gui.speedInTitleBar },
            AppCommand(.lock, String(localized: "Lock qBittorrent Neo"), symbol: Symbol.lock, shortcut: CommandShortcut("l"),
                       keywords: words(String(localized: "palette.keywords.lock", defaultValue: "password, privacy",
                                              comment: "Command Palette search words, comma-separated"))) {
                $0.model.requestLock()
            },
            AppCommand(.setLockPassword, String(localized: "Set Password…"), symbol: Symbol.key) {
                $0.model.sheet = .lockPassword(lockAfterSaving: false)
            },
        ]
    }

    /// The details (properties) pane and its tabs (⌥ + qBittorrent's Alt letters).
    private static var detailsCommands: [AppCommand] {
        let tabs: [(CommandID, PropertiesTab)] = [
            (.detailsGeneral, .general), (.detailsTrackers, .trackers), (.detailsPeers, .peers),
            (.detailsHTTPSources, .httpSources), (.detailsContent, .content), (.detailsSpeed, .speed),
        ]
        let toggle = AppCommand(.toggleDetails, String(localized: "Details Pane"), symbol: Symbol.rectangleBottomHalfInsetFilled,
                                keywords: words(String(localized: "palette.keywords.details", defaultValue: "properties, info, panel",
                                                       comment: "Command Palette search words, comma-separated"))) { $0.model.gui.propertiesVisible.toggle() }
            .state { $0.gui.propertiesVisible }
        return [toggle] + tabs.map { id, tab in
            AppCommand(id, String(localized: "\(tab.title) Tab", comment: "Command Palette: show a tab of the details pane"),
                       symbol: tab.systemImage, shortcut: CommandShortcut(KeyEquivalent(tab.shortcutKey), .option),
                       keywords: words(String(localized: "palette.keywords.details", defaultValue: "properties, info, panel",
                                              comment: "Command Palette search words, comma-separated"))) {
                $0.model.gui.propertiesTab = tab
                $0.model.gui.propertiesVisible = true
            }
        }
    }

    private static var windowCommands: [AppCommand] {
        [
            AppCommand(.searchEngine, String(localized: "Search Engine"), symbol: Symbol.magnifyingglass,
                       shortcut: CommandShortcut("2", .option)) { $0.model.show(.search) },
            AppCommand(.rssReader, String(localized: "RSS Reader"), symbol: Symbol.dotRadiowavesUpForward,
                       shortcut: CommandShortcut("3", .option),
                       keywords: words(String(localized: "palette.keywords.rss", defaultValue: "feeds, news, subscriptions",
                                              comment: "Command Palette search words, comma-separated"))) { $0.model.show(.rss) },
            AppCommand(.executionLog, String(localized: "Show Execution Log"), symbol: Symbol.textAlignleft,
                       shortcut: CommandShortcut("4", .option)) { $0.model.show(.log) },
            AppCommand(.statistics, String(localized: "Statistics"), symbol: Symbol.chartBar,
                       shortcut: CommandShortcut("i")) { $0.model.show(.statistics) },
            AppCommand(.torrentCreator, String(localized: "Torrent Creator"), symbol: Symbol.wandAndStars, shortcut: CommandShortcut("n"),
                       keywords: words(String(localized: "palette.keywords.creator", defaultValue: "new, make, create",
                                              comment: "Command Palette search words, comma-separated"))) { $0.model.show(.creator) },
            AppCommand(.manageCookies, String(localized: "Manage Cookies…"), symbol: Symbol.listBulletRectangle) { $0.model.show(.cookies) },
            AppCommand(.options, String(localized: "Options…"), symbol: Symbol.gearshape, shortcut: CommandShortcut("o", .option),
                       keywords: words(String(localized: "palette.keywords.settings", defaultValue: "settings, preferences",
                                              comment: "Command Palette search words, comma-separated"))) { $0.model.showSettings() },
            AppCommand(.about, String(localized: "About qBittorrent Neo"), symbol: Symbol.infoCircle) { $0.model.show(.about) },
            AppCommand(.documentation, String(localized: "Documentation"), symbol: Symbol.questionmarkCircle,
                       shortcut: CommandShortcut("?"),
                       keywords: words(String(localized: "palette.keywords.help", defaultValue: "help, manual",
                                              comment: "Command Palette search words, comma-separated"))) { _ in
                if let url = URL(string: "https://doc.qbittorrent.org") { NSWorkspace.shared.open(url) }
            },
        ]
    }
}
