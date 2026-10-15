#if DEBUG
import Foundation

/// Debug self-check: every stored preference appears in the settings catalog
/// exactly once (docs/design/settings-ia.md §8 in executable form). Runs once
/// when the Settings window opens in debug builds.
@MainActor
enum SettingsCatalogCheck {
    /// `/api/v2/app/preferences` GET keys plus `web_ui_password` (preferences.md Appendix A).
    static let apiKeys: [String] = [
        "locale", "performance_warning", "status_bar_external_ip", "confirm_torrent_deletion", "file_log_enabled", "file_log_path",
        "file_log_backup_enabled", "file_log_max_size", "file_log_delete_old", "file_log_age", "file_log_age_type",
        "delete_torrent_content_files", "torrent_content_layout", "add_to_top_of_queue", "add_stopped_enabled", "torrent_stop_condition",
        "merge_trackers", "auto_delete_mode", "preallocate_all", "incomplete_files_ext", "use_unwanted_folder", "auto_tmm_enabled",
        "torrent_changed_tmm_enabled", "save_path_changed_tmm_enabled", "category_changed_tmm_enabled", "save_path", "temp_path_enabled",
        "temp_path", "use_category_paths_in_manual_mode", "export_dir", "export_dir_fin", "scan_dirs", "excluded_file_names_enabled",
        "excluded_file_names", "mail_notification_enabled", "mail_notification_sender", "mail_notification_email", "mail_notification_smtp",
        "mail_notification_ssl_enabled", "mail_notification_auth_enabled", "mail_notification_username", "mail_notification_password",
        "autorun_on_torrent_added_enabled", "autorun_on_torrent_added_program", "autorun_enabled", "autorun_program", "listen_port",
        "ssl_enabled", "ssl_listen_port", "random_port", "upnp", "max_connec", "max_connec_per_torrent", "max_uploads",
        "max_uploads_per_torrent", "i2p_enabled", "i2p_address", "i2p_port", "i2p_mixed_mode", "i2p_inbound_quantity",
        "i2p_outbound_quantity", "i2p_inbound_length", "i2p_outbound_length", "proxy_type", "proxy_ip", "proxy_port", "proxy_auth_enabled",
        "proxy_username", "proxy_password", "proxy_hostname_lookup", "proxy_bittorrent", "proxy_peer_connections", "proxy_rss",
        "proxy_misc", "ip_filter_enabled", "ip_filter_path", "ip_filter_trackers", "banned_IPs", "dl_limit", "up_limit", "alt_dl_limit",
        "alt_up_limit", "bittorrent_protocol", "limit_utp_rate", "limit_tcp_overhead", "limit_lan_peers", "scheduler_enabled",
        "schedule_from_hour", "schedule_from_min", "schedule_to_hour", "schedule_to_min", "scheduler_days", "dht", "pex", "lsd",
        "encryption", "anonymous_mode", "max_active_checking_torrents", "queueing_enabled", "max_active_downloads", "max_active_torrents",
        "max_active_uploads", "dont_count_slow_torrents", "slow_torrent_dl_rate_threshold", "slow_torrent_ul_rate_threshold",
        "slow_torrent_inactive_timer", "max_ratio_enabled", "max_ratio", "max_seeding_time_enabled", "max_seeding_time",
        "max_inactive_seeding_time_enabled", "max_inactive_seeding_time", "max_ratio_act", "add_trackers_enabled", "add_trackers",
        "add_trackers_from_url_enabled", "add_trackers_url", "add_trackers_url_list", "web_ui_domain_list", "web_ui_address", "web_ui_port",
        "web_ui_upnp", "use_https", "web_ui_https_cert_path", "web_ui_https_key_path", "web_ui_username", "web_ui_password",
        "bypass_local_auth", "bypass_auth_subnet_whitelist_enabled", "bypass_auth_subnet_whitelist", "web_ui_max_auth_fail_count",
        "web_ui_ban_duration", "web_ui_session_timeout", "web_ui_api_key", "alternative_webui_enabled", "alternative_webui_path",
        "web_ui_clickjacking_protection_enabled", "web_ui_csrf_protection_enabled", "web_ui_secure_cookie_enabled",
        "web_ui_host_header_validation_enabled", "web_ui_use_custom_http_headers_enabled", "web_ui_custom_http_headers",
        "web_ui_reverse_proxy_enabled", "web_ui_reverse_proxies_list", "dyndns_enabled", "dyndns_service", "dyndns_username",
        "dyndns_password", "dyndns_domain", "rss_refresh_interval", "rss_fetch_delay", "rss_max_articles_per_feed",
        "rss_processing_enabled", "rss_auto_downloading_enabled", "rss_download_repack_proper_episodes", "rss_smart_episode_filters",
        "resume_data_storage_type", "torrent_content_remove_option", "memory_working_set_limit", "current_network_interface",
        "current_interface_name", "current_interface_address", "save_resume_data_interval", "save_statistics_interval",
        "torrent_file_size_limit", "confirm_torrent_recheck", "recheck_completed_torrents", "app_instance_name", "refresh_interval",
        "resolve_peer_host_names", "resolve_peer_countries", "reannounce_when_address_changed", "enable_embedded_tracker",
        "embedded_tracker_port", "embedded_tracker_port_forwarding", "mark_of_the_web", "ignore_ssl_errors", "python_executable_path",
        "bdecode_depth_limit", "bdecode_token_limit", "async_io_threads", "hashing_threads", "file_pool_size", "checking_memory_use",
        "disk_cache", "disk_cache_ttl", "disk_queue_size", "disk_io_type", "disk_io_read_mode", "disk_io_write_mode",
        "enable_coalesce_read_write", "enable_piece_extent_affinity", "enable_upload_suggestions", "send_buffer_watermark",
        "send_buffer_low_watermark", "send_buffer_watermark_factor", "connection_speed", "socket_send_buffer_size",
        "socket_receive_buffer_size", "socket_backlog_size", "outgoing_ports_min", "outgoing_ports_max", "upnp_lease_duration", "peer_tos",
        "utp_tcp_mixed_mode", "hostname_cache_ttl", "idn_support_enabled", "enable_multi_connections_from_same_ip",
        "validate_https_tracker_certificate", "ssrf_mitigation", "block_peers_on_privileged_ports", "upload_slots_behavior",
        "upload_choking_algorithm", "announce_to_all_trackers", "announce_to_all_tiers", "announce_ip", "announce_port",
        "max_concurrent_http_announces", "stop_tracker_timeout", "peer_turnover", "peer_turnover_cutoff", "peer_turnover_interval",
        "request_queue_size", "dht_bootstrap_nodes",
    ]

    /// GUI-only keys with a Settings control (settings-ia.md §8.2).
    static var guiKeys: [String] {
        let gui: [GUIPreferenceKey] = [
            .colorScheme, .alternatingRowColors, .useTorrentStatesColors, .progressBarFollowsTextColor, .hideZeroValues,
            .hideZeroComboValues, .doubleClickDownloading, .doubleClickCompleted, .hideZeroStatusFilters, .separateTrackerStatusFilter,
            .torrentContentDragEnabled, .startupWindowState, .confirmOnExit, .dontConfirmAutoExit, .showSpeedInDock, .showMenuBarIcon,
            .menuBarContentMode, .menuBarShowsIcon, .menuBarSpeedDirection, .menuBarHidesZeroSpeed, .menuBarCountStyle,
            .preventSuspendWhenDownloading, .preventSuspendWhenSeeding, .statusBarFreeDiskSpace, .checkForUpdates,
            .addTorrentDialogEnabled, .addTorrentDialogTopLevel, .confirmMergeTrackers, .disableRecursiveDownload,
            .notificationsEnabled, .notifyTorrentAdded, .confirmRemoveAllTags, .confirmRemoveTrackerFromAllTorrents,
            .downloadTrackerFavicon, .savePathHistoryLength, .speedGraphsEnabled, .rssEnabled, .searchEnabled, .lockPasswordHash,
        ]
        return gui.map(\.rawValue) + [
            FeatureDefaults.storeSearchTabs, FeatureDefaults.storeSearchResults, FeatureDefaults.searchHistoryLength,
            SettingsNavigator.showAdvancedKey, "watched_folders.json", "Preferences/WebUI/Enabled",
            "BitTorrent/Session/StartPaused", "BitTorrent/Session/ShutdownTimeout",
            "LaunchServices (.torrent)", "LaunchServices (magnet:)",
        ]
    }

    /// Problems found (empty when the catalog is complete).
    static func problems() -> [String] {
        var problems: [String] = []
        var counts: [String: Int] = [:]
        for key in SettingsCatalog.all.flatMap(\.keys) { counts[key, default: 0] += 1 }
        for key in apiKeys + guiKeys {
            let count = counts[key] ?? 0
            if count != 1 { problems.append("\(key): \(count) catalog entries") }
        }
        let expected = Set(apiKeys + guiKeys)
        problems += counts.keys.filter { !expected.contains($0) }.sorted().map { "\($0): not a known key" }
        var ids: [String: Int] = [:]
        for spec in SettingsCatalog.all { ids[spec.id, default: 0] += 1 }
        problems += ids.filter { $0.value > 1 }.keys.sorted().map { "\($0): duplicate id" }
        return problems
    }

    /// Logs and asserts when the catalog is incomplete.
    static func verify() {
        let found = problems()
        if !found.isEmpty {
            NSLog("Settings catalog problems: %@", found.joined(separator: "; "))
            assertionFailure("Settings catalog problems: \(found.joined(separator: "; "))")
        }
    }
}
#endif
