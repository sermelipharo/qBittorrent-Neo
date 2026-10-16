import Foundation

extension SettingsCatalog {
    static var general: [SettingSpec] {
        [
            SettingSpec("system.openAtLogin", .startup, String(localized: "Open qBittorrent Neo at login"),
                        keywords: ["login item", "launch", "autostart", "SMAppService"]),
            SettingSpec("GUI/StartUpWindowState", .startup, String(localized: "At startup, show window:"), keywords: ["minimized"]),
            SettingSpec("BitTorrent/Session/StartPaused", .startup, String(localized: "Start with all transfers paused"), .advanced,
                        help: String(localized: "Nothing downloads or uploads until you resume."),
                        check: .pref(\.advanced.startPaused)),

            SettingSpec("system.torrentHandler", .defaultApp, String(localized: ".torrent files"),
                        keys: ["LaunchServices (.torrent)"], keywords: ["default application", "file association", "open with"]),
            SettingSpec("system.magnetHandler", .defaultApp, String(localized: "Magnet links"),
                        keys: ["LaunchServices (magnet:)"], keywords: ["default application", "magnet:", "browser"]),

            SettingSpec("Preferences/Desktop/ShowSpeedInDock", .dockMenuBar, String(localized: "Show speed in Dock"), keywords: ["badge"]),
            SettingSpec("Preferences/Desktop/ShowMacOSMenuBarIcon", .dockMenuBar, String(localized: "Show qBittorrent Neo in menu bar"),
                        keywords: ["status item", "menu extra"]),
            SettingSpec("Preferences/Desktop/MenuBarContentMode", .dockMenuBar, String(localized: "Menu bar shows:"),
                        keywords: ["status item", "speed", "torrent count", "icon only", "upload", "download"]),
            SettingSpec("Preferences/Desktop/MenuBarSpeedDirection", .dockMenuBar, String(localized: "Menu bar speed:"), .advanced,
                        keywords: ["status item", "download", "upload", "direction", "rate"]),
            SettingSpec("Preferences/Desktop/MenuBarHidesZeroSpeed", .dockMenuBar, String(localized: "Hide idle speeds in menu bar"), .advanced,
                        help: String(localized: "The item shrinks to its icon while nothing transfers."),
                        keywords: ["status item", "zero", "idle", "width"]),
            SettingSpec("Preferences/Desktop/MenuBarCountStyle", .dockMenuBar, String(localized: "Menu bar torrent count:"), .advanced,
                        keywords: ["status item", "active", "total", "number of torrents"]),
            SettingSpec("Preferences/Desktop/MenuBarShowsIcon", .dockMenuBar, String(localized: "Show icon next to the text in menu bar"), .advanced,
                        help: String(localized: "The icon always appears when there is no text."),
                        keywords: ["status item", "symbol", "text only"]),

            SettingSpec("GUI/Notifications/Enabled", .notifications, String(localized: "Display notifications"),
                        help: String(localized: "When a download finishes or a file can't be written.")),
            SettingSpec("Application/GUI/Notifications/TorrentAdded", .notifications, String(localized: "Also when a torrent is added"), .revealed),
            SettingSpec("system.notificationSettings", .notifications, String(localized: "Notification Settings…"),
                        keywords: ["banner", "alert", "sound", "System Settings"]),
            SettingSpec("mail_notification_enabled", .notifications, String(localized: "Send an email when a download finishes"),
                        keywords: ["email", "e-mail", "mail", "SMTP"]),
            SettingSpec("mail_notification_sender", .notifications, String(localized: "From:"), .revealed, keywords: ["email"]),
            SettingSpec("mail_notification_email", .notifications, String(localized: "To:"), .revealed, keywords: ["email"]),
            SettingSpec("mail_notification_smtp", .notifications, String(localized: "SMTP server:"), .revealed),
            SettingSpec("mail_notification_ssl_enabled", .notifications, String(localized: "This server requires a secure connection (SSL)"),
                        .revealed, keywords: ["TLS", "SMTP"]),
            SettingSpec("mail_notification_auth_enabled", .notifications, String(localized: "Authentication"), .revealed, keywords: ["SMTP"]),
            SettingSpec("mail_notification_username", .notifications, String(localized: "Username:"), .revealed, keywords: ["SMTP", "email"]),
            SettingSpec("mail_notification_password", .notifications, String(localized: "Password:"), .revealed, keywords: ["SMTP", "email"]),
            SettingSpec("system.testEmail", .notifications, String(localized: "Send test email"), .revealed, keywords: ["SMTP"]),

            SettingSpec("Preferences/General/PreventFromSuspendWhenDownloading", .powerManagement,
                        String(localized: "Keep Mac awake while downloading"), keywords: ["sleep", "inhibit", "caffeinate"]),
            SettingSpec("Preferences/General/PreventFromSuspendWhenSeeding", .powerManagement,
                        String(localized: "Keep Mac awake while seeding"), help: String(localized: "The display can still sleep."),
                        keywords: ["sleep", "inhibit", "caffeinate"]),

            SettingSpec("confirm_torrent_deletion", .confirmations, String(localized: "Ask before deleting torrents"),
                        keywords: ["confirm", "remove"]),
            SettingSpec("Preferences/General/ExitConfirm", .confirmations, String(localized: "Ask before quitting while torrents are active"),
                        keywords: ["confirm", "quit", "exit"]),
            SettingSpec("ShutdownConfirmDlg/DontConfirmAutoExit", .confirmations,
                        String(localized: "Show a countdown before quitting when downloads finish"), keywords: ["confirm", "auto-exit", "shutdown"]),
            SettingSpec("confirm_torrent_recheck", .confirmations, String(localized: "Ask before rechecking torrents"), .disclosure,
                        keywords: ["confirm", "recheck", "force recheck"]),
            SettingSpec("Preferences/Advanced/confirmRemoveAllTags", .confirmations, String(localized: "Ask before removing all tags"),
                        .disclosure, keywords: ["confirm", "tags"]),
            SettingSpec("GUI/ConfirmActions/RemoveTrackerFromAllTorrents", .confirmations,
                        String(localized: "Ask before removing a tracker from all torrents"), .disclosure, keywords: ["confirm", "tracker"]),
            SettingSpec("delete_torrent_content_files", .confirmations, String(localized: "Delete files by default when removing torrents"),
                        .disclosure, keywords: ["remove", "delete", "content"]),

            SettingSpec("Preferences/Advanced/updateCheck", .updates, String(localized: "Check for updates automatically"),
                        keywords: ["update", "new version"]),

            SettingSpec("locale", .language, String(localized: "Language:"), .advanced,
                        help: String(localized: "Changes take effect after relaunch."), keywords: ["locale", "translation"],
                        check: .pref(\.behavior.locale)),
        ]
    }

    static var interface: [SettingSpec] {
        [
            SettingSpec("Appearance/ColorScheme", .appearance, String(localized: "Color scheme:"),
                        help: String(localized: "System follows your Mac's appearance."), keywords: ["dark mode", "light mode", "theme"]),

            SettingSpec("Preferences/General/AlternatingRowColors", .torrentList, String(localized: "Use alternating row colors"),
                        keywords: ["stripes", "zebra"]),
            SettingSpec("GUI/TransferList/StateColorScope", .torrentList, String(localized: "Color by state:"),
                        help: String(localized: "Which parts of a row take the color of the torrent's state."),
                        keywords: ["text colors", "progress bar color", "status color", "row color", "highlight"]),
            SettingSpec("Preferences/General/HideZeroValues", .torrentList, String(localized: "Hide zero and infinity values"),
                        keys: ["Preferences/General/HideZeroValues", "Preferences/General/HideZeroComboValues"]),

            SettingSpec("Preferences/Downloads/DblClOnTorDl", .doubleClick, String(localized: "Downloading torrents:"), keywords: ["double-click"]),
            SettingSpec("Preferences/Downloads/DblClOnTorFn", .doubleClick, String(localized: "Completed torrents:"), keywords: ["double-click"]),

            SettingSpec("TransferListFilters/HideZeroStatusFilters", .sidebar, String(localized: "Hide empty status filters"),
                        keywords: ["filters"]),
            SettingSpec("TransferListFilters/SeparateTrackerStatusFilter", .sidebar, String(localized: "Use separate \"Tracker status\" filter"),
                        keywords: ["filters"]),
            SettingSpec("GUI/DownloadTrackerFavicon", .sidebar, String(localized: "Show tracker icons"),
                        help: String(localized: "Downloads each tracker website's icon."), keywords: ["favicon"]),

            SettingSpec("SpeedWidget/Enabled", .torrentDetails, String(localized: "Show speed graphs"), keywords: ["chart"]),
            SettingSpec("Preferences/General/TorrentContentDragEnabled", .torrentDetails,
                        String(localized: "Drag files from the Content tab to Finder"), keywords: ["drag and drop"]),

            SettingSpec("Preferences/General/StatusbarFreeDiskSpaceDisplayed", .statusBar, String(localized: "Show free disk space")),
            SettingSpec("status_bar_external_ip", .statusBar, String(localized: "Show external IP address"), keywords: ["public IP"]),

            SettingSpec("resolve_peer_countries", .peersList, String(localized: "Show peer countries"), .advanced,
                        help: String(localized: "Uses a free IP-to-country database downloaded monthly."), keywords: ["flags", "GeoIP", "resolve"],
                        check: .pref(\.advanced.resolvePeerCountries)),
            SettingSpec("resolve_peer_host_names", .peersList, String(localized: "Show peer host names"), .advanced,
                        help: String(localized: "Looks up every peer's name; adds network traffic."), keywords: ["resolve", "DNS"],
                        check: .pref(\.advanced.resolvePeerHostNames)),

            SettingSpec("refresh_interval", .window, String(localized: "Update interval:"), .advanced,
                        help: String(localized: "How often lists and speeds refresh. Lower values use more CPU."), keywords: ["refresh"],
                        check: .pref(\.advanced.refreshInterval)),
            SettingSpec("app_instance_name", .window, String(localized: "Window title suffix:"), .advanced,
                        help: String(localized: "Helps tell several copies of the app apart."), keywords: ["instance name"],
                        check: .pref(\.advanced.appInstanceName)),
        ]
    }
}
