import Foundation

extension SettingsCatalog {
    static var transfers: [SettingSpec] {
        adding + files + seeding
    }

    private static var adding: [SettingSpec] {
        [
            SettingSpec("save_path", .saveLocation, String(localized: "Save downloads to:"),
                        keywords: ["download folder", "destination", "default save path"]),
            SettingSpec("temp_path_enabled", .saveLocation, String(localized: "Keep incomplete downloads in:"),
                        help: String(localized: "Finished downloads move to the save location."),
                        keys: ["temp_path_enabled", "temp_path"], keywords: ["temporary", "incomplete"]),

            SettingSpec("AddNewTorrentDialog/Enabled", .addingTorrents, String(localized: "Show options when adding a torrent"),
                        keywords: ["add torrent dialog"]),
            SettingSpec("AddNewTorrentDialog/TopLevel", .addingTorrents, String(localized: "Bring torrent dialog to the front"), .revealed),
            SettingSpec("add_stopped_enabled", .addingTorrents, String(localized: "Start downloads automatically"),
                        keywords: ["paused", "stopped", "do not start"]),
            SettingSpec("torrent_stop_condition", .addingTorrents, String(localized: "Torrent stop condition:"), .advanced,
                        keywords: ["metadata"], check: .pref(\.downloads.torrentStopCondition)),
            SettingSpec("torrent_content_layout", .addingTorrents, String(localized: "Torrent content layout:"), .advanced,
                        keywords: ["subfolder"], check: .pref(\.downloads.torrentContentLayout)),
            SettingSpec("add_to_top_of_queue", .addingTorrents, String(localized: "Add to top of queue"), .advanced,
                        check: .pref(\.downloads.addToTopOfQueue)),
            SettingSpec("AddNewTorrentDialog/SavePathHistoryLength", .addingTorrents, String(localized: "Remember recent save locations:"),
                        .advanced, keywords: ["history"], check: .gui(\.savePathHistoryLength, 8)),

            SettingSpec("scan_dirs", .watchedFolders, String(localized: "Automatically add torrents from:"),
                        help: String(localized: ".torrent files saved into these folders are added automatically."),
                        keys: ["scan_dirs", "watched_folders.json"], keywords: ["watch", "monitor", "scan"]),

            SettingSpec("merge_trackers", .duplicateTorrents, String(localized: "Merge trackers to existing torrent"),
                        check: .pref(\.downloads.mergeTrackers)),
            SettingSpec("GUI/ConfirmActions/MergeTrackers", .duplicateTorrents,
                        String(localized: "Ask to merge trackers for manually added torrent"), check: .gui(\.confirmMergeTrackers, true)),

            SettingSpec("auto_delete_mode", .torrentFiles, String(localized: "Delete .torrent files afterwards"),
                        check: .pref(\.downloads.autoDeleteMode)),
            SettingSpec("export_dir", .torrentFiles, String(localized: "Copy .torrent files to:"), check: .pref(\.downloads.exportDir)),
            SettingSpec("export_dir_fin", .torrentFiles, String(localized: "Copy .torrent files for finished downloads to:"),
                        check: .pref(\.downloads.exportDirFin)),

            SettingSpec("add_trackers_enabled", .extraTrackers, String(localized: "Automatically append these trackers to new downloads:"),
                        keys: ["add_trackers_enabled", "add_trackers"], check: .pref(\.bittorrent.addTrackersEnabled)),
            SettingSpec("add_trackers_from_url_enabled", .extraTrackers,
                        String(localized: "Automatically append trackers from URL to new downloads:"),
                        keys: ["add_trackers_from_url_enabled", "add_trackers_url", "add_trackers_url_list"],
                        check: .pref(\.bittorrent.addTrackersFromUrlEnabled)),
        ]
    }

    private static var files: [SettingSpec] {
        [
            SettingSpec("torrent_content_remove_option", .removingTorrents, String(localized: "When removing a torrent with its files:"),
                        keywords: ["trash", "delete permanently"]),

            SettingSpec("preallocate_all", .filesOnDisk, String(localized: "Pre-allocate disk space for all files"),
                        check: .pref(\.downloads.preallocateAll)),
            SettingSpec("incomplete_files_ext", .filesOnDisk, String(localized: "Append .!qB extension to incomplete files"),
                        check: .pref(\.downloads.incompleteFilesExt)),
            SettingSpec("use_unwanted_folder", .filesOnDisk, String(localized: "Keep unselected files in \".unwanted\" folder"),
                        check: .pref(\.downloads.useUnwantedFolder)),
            SettingSpec("recheck_completed_torrents", .filesOnDisk, String(localized: "Verify files again when a download finishes"),
                        keywords: ["recheck"], check: .pref(\.advanced.recheckCompletedTorrents)),
            SettingSpec("Preferences/Advanced/DisableRecursiveDownload", .filesOnDisk,
                        String(localized: "Offer to add .torrent files found inside downloads"), keywords: ["recursive"],
                        check: .gui(\.recursiveDownloadEnabled, true)),
            SettingSpec("excluded_file_names_enabled", .filesOnDisk, String(localized: "Excluded file names"),
                        keys: ["excluded_file_names_enabled", "excluded_file_names"], keywords: ["blacklist", "skip files"],
                        check: .prefs(\.downloads.excludedFileNamesEnabled, \.downloads.excludedFileNames)),

            SettingSpec("auto_tmm_enabled", .categories, String(localized: "Default Torrent Management Mode:"),
                        help: String(localized: "Automatic: the category decides the save location."), keywords: ["TMM", "automatic mode"],
                        check: .pref(\.downloads.autoTmmEnabled)),
            SettingSpec("torrent_changed_tmm_enabled", .categories, String(localized: "When Torrent Category changed:"),
                        check: .pref(\.downloads.torrentChangedTmmEnabled)),
            SettingSpec("save_path_changed_tmm_enabled", .categories, String(localized: "When Default Save/Incomplete Path changed:"),
                        check: .pref(\.downloads.savePathChangedTmmEnabled)),
            SettingSpec("category_changed_tmm_enabled", .categories, String(localized: "When Category Save Path changed:"),
                        check: .pref(\.downloads.categoryChangedTmmEnabled)),
            SettingSpec("use_category_paths_in_manual_mode", .categories, String(localized: "Use Category paths in Manual Mode"),
                        check: .pref(\.downloads.useCategoryPathsInManualMode)),

            SettingSpec("autorun_on_torrent_added_enabled", .runProgram, String(localized: "Run on torrent added:"),
                        keys: ["autorun_on_torrent_added_enabled", "autorun_on_torrent_added_program"], keywords: ["script", "external program"],
                        check: .pref(\.downloads.autorunOnTorrentAddedEnabled)),
            SettingSpec("autorun_enabled", .runProgram, String(localized: "Run on torrent finished:"),
                        keys: ["autorun_enabled", "autorun_program"], keywords: ["script", "external program"],
                        check: .pref(\.downloads.autorunEnabled)),
        ]
    }

    private static var seeding: [SettingSpec] {
        [
            SettingSpec("max_ratio_enabled", .seedingLimits, String(localized: "When ratio reaches"),
                        keys: ["max_ratio_enabled", "max_ratio"], keywords: ["ratio", "share ratio", "seeding limit"]),
            SettingSpec("max_seeding_time_enabled", .seedingLimits, String(localized: "When total seeding time reaches"),
                        keys: ["max_seeding_time_enabled", "max_seeding_time"], keywords: ["seeding limit"]),
            SettingSpec("max_inactive_seeding_time_enabled", .seedingLimits, String(localized: "When inactive seeding time reaches"),
                        keys: ["max_inactive_seeding_time_enabled", "max_inactive_seeding_time"], keywords: ["seeding limit"]),
            SettingSpec("max_ratio_act", .seedingLimits, String(localized: "then"), keywords: ["ratio", "super seeding", "remove"]),

            SettingSpec("queueing_enabled", .queue, String(localized: "Limit the number of active torrents"),
                        keywords: ["queueing", "queue"]),
            SettingSpec("max_active_downloads", .queue, String(localized: "Maximum active downloads:"), .revealed, keywords: ["queue"]),
            SettingSpec("max_active_uploads", .queue, String(localized: "Maximum active uploads:"), .revealed, keywords: ["queue"]),
            SettingSpec("max_active_torrents", .queue, String(localized: "Maximum active torrents:"), .revealed, keywords: ["queue"]),
            SettingSpec("dont_count_slow_torrents", .queue, String(localized: "Do not count slow torrents in these limits"), .advanced,
                        check: .pref(\.bittorrent.dontCountSlowTorrents)),
            SettingSpec("slow_torrent_dl_rate_threshold", .queue, String(localized: "Download rate threshold:"), .advanced,
                        keywords: ["slow torrents"], check: .pref(\.bittorrent.slowTorrentDlRateThreshold)),
            SettingSpec("slow_torrent_ul_rate_threshold", .queue, String(localized: "Upload rate threshold:"), .advanced,
                        keywords: ["slow torrents"], check: .pref(\.bittorrent.slowTorrentUlRateThreshold)),
            SettingSpec("slow_torrent_inactive_timer", .queue, String(localized: "Torrent inactivity timer:"), .advanced,
                        keywords: ["slow torrents"], check: .pref(\.bittorrent.slowTorrentInactiveTimer)),

            SettingSpec("max_active_checking_torrents", .checking, String(localized: "Maximum active checking torrents:"),
                        keywords: ["recheck"], check: .pref(\.bittorrent.maxActiveCheckingTorrents)),
        ]
    }
}
