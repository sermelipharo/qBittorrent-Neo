import Foundation

extension SettingsCatalog {
    static var advanced: [SettingSpec] {
        [
            SettingSpec("Settings/ShowAdvanced", .showAdvanced, String(localized: "Show advanced settings"),
                        help: String(localized: "Adds advanced sections to every pane and shows libtorrent tuning below. Hidden settings keep working."),
                        keywords: ["expert", "power user", "libtorrent"]),
        ] + expertLogs + expertEngine + expertNetwork + expertTrackers
    }

    private static func expert<Value: Equatable>(
        _ id: String, _ section: SettingsSection, _ title: String, _ path: KeyPath<Preferences, Value>, keys: [String]? = nil
    ) -> SettingSpec {
        SettingSpec(id, section, title, .expert, keys: keys, check: .pref(path))
    }

    private static var expertLogs: [SettingSpec] {
        [
            expert("file_log_enabled", .logs, String(localized: "Log Files"), \.behavior.fileLogEnabled),
            expert("file_log_path", .logs, String(localized: "Save path:"), \.behavior.fileLogPath),
            expert("file_log_backup_enabled", .logs, String(localized: "Backup the log file after:"), \.behavior.fileLogBackupEnabled,
                   keys: ["file_log_backup_enabled", "file_log_max_size"]),
            expert("file_log_delete_old", .logs, String(localized: "Delete backup logs older than:"), \.behavior.fileLogDeleteOld,
                   keys: ["file_log_delete_old", "file_log_age", "file_log_age_type"]),
            expert("performance_warning", .logs, String(localized: "Log performance warnings"), \.behavior.performanceWarning),
            expert("resume_data_storage_type", .dataRecovery, String(localized: "Resume data storage type (requires restart)"),
                   \.advanced.resumeDataStorageType),
            expert("save_resume_data_interval", .dataRecovery, String(localized: "Save resume data interval [0: disabled]"),
                   \.advanced.saveResumeDataInterval),
            expert("save_statistics_interval", .dataRecovery, String(localized: "Save statistics interval [0: disabled]"),
                   \.advanced.saveStatisticsInterval),
            expert("BitTorrent/Session/ShutdownTimeout", .dataRecovery, String(localized: "BitTorrent session shutdown timeout [-1: unlimited]"),
                   \.advanced.shutdownTimeout),
        ]
    }

    private static var expertEngine: [SettingSpec] {
        [
            expert("async_io_threads", .diskMemory, String(localized: "Asynchronous I/O threads"), \.advanced.asyncIoThreads),
            expert("hashing_threads", .diskMemory, String(localized: "Hashing threads"), \.advanced.hashingThreads),
            expert("file_pool_size", .diskMemory, String(localized: "File pool size"), \.advanced.filePoolSize),
            expert("checking_memory_use", .diskMemory, String(localized: "Outstanding memory when checking torrents"), \.advanced.checkingMemoryUse),
            expert("disk_queue_size", .diskMemory, String(localized: "Disk queue size"), \.advanced.diskQueueSize),
            expert("disk_io_type", .diskMemory, String(localized: "Disk IO type (requires restart)"), \.advanced.diskIoType),
            expert("disk_io_read_mode", .diskMemory, String(localized: "Disk IO read mode"), \.advanced.diskIoReadMode),
            expert("disk_io_write_mode", .diskMemory, String(localized: "Disk IO write mode"), \.advanced.diskIoWriteMode),
            expert("enable_piece_extent_affinity", .diskMemory, String(localized: "Use piece extent affinity"),
                   \.advanced.enablePieceExtentAffinity),
            SettingSpec("memory_working_set_limit", .diskMemory, "memory_working_set_limit", .platform),
            SettingSpec("disk_cache", .diskMemory, "disk_cache", .platform),
            SettingSpec("disk_cache_ttl", .diskMemory, "disk_cache_ttl", .platform),
            SettingSpec("enable_coalesce_read_write", .diskMemory, "enable_coalesce_read_write", .platform),
            expert("torrent_file_size_limit", .safetyLimits, String(localized: ".torrent file size limit"), \.advanced.torrentFileSizeLimit),
            expert("bdecode_depth_limit", .safetyLimits, String(localized: "Bdecode depth limit"), \.advanced.bdecodeDepthLimit),
            expert("bdecode_token_limit", .safetyLimits, String(localized: "Bdecode token limit"), \.advanced.bdecodeTokenLimit),
        ]
    }

    private static var expertNetwork: [SettingSpec] {
        [
            expert("connection_speed", .networkTuning, String(localized: "Outgoing connections per second"), \.advanced.connectionSpeed),
            expert("socket_send_buffer_size", .networkTuning, String(localized: "Socket send buffer size [0: system default]"),
                   \.advanced.socketSendBufferSize),
            expert("socket_receive_buffer_size", .networkTuning, String(localized: "Socket receive buffer size [0: system default]"),
                   \.advanced.socketReceiveBufferSize),
            expert("socket_backlog_size", .networkTuning, String(localized: "Socket backlog size"), \.advanced.socketBacklogSize),
            expert("outgoing_ports_min", .networkTuning, String(localized: "Outgoing ports (Min) [0: disabled]"), \.advanced.outgoingPortsMin),
            expert("outgoing_ports_max", .networkTuning, String(localized: "Outgoing ports (Max) [0: disabled]"), \.advanced.outgoingPortsMax),
            expert("upnp_lease_duration", .networkTuning, String(localized: "UPnP lease duration [0: permanent lease]"),
                   \.advanced.upnpLeaseDuration),
            expert("peer_tos", .networkTuning, String(localized: "Differentiated Services Code Point (DSCP) for connections to peers"),
                   \.advanced.peerTos),
            expert("utp_tcp_mixed_mode", .networkTuning, String(localized: "μTP-TCP mixed mode algorithm"), \.advanced.utpTcpMixedMode),
            expert("hostname_cache_ttl", .networkTuning, String(localized: "Internal hostname resolver cache expiry interval"),
                   \.advanced.hostnameCacheTtl),
            expert("enable_multi_connections_from_same_ip", .networkTuning,
                   String(localized: "Allow multiple connections from the same IP address"), \.advanced.enableMultiConnectionsFromSameIp),
            expert("enable_upload_suggestions", .networkTuning, String(localized: "Send upload piece suggestions"),
                   \.advanced.enableUploadSuggestions),
            expert("send_buffer_watermark", .networkTuning, String(localized: "Send buffer watermark"), \.advanced.sendBufferWatermark),
            expert("send_buffer_low_watermark", .networkTuning, String(localized: "Send buffer low watermark"),
                   \.advanced.sendBufferLowWatermark),
            expert("send_buffer_watermark_factor", .networkTuning, String(localized: "Send buffer watermark factor"),
                   \.advanced.sendBufferWatermarkFactor),
            expert("upload_slots_behavior", .peersUploading, String(localized: "Upload slots behavior"), \.advanced.uploadSlotsBehavior),
            expert("upload_choking_algorithm", .peersUploading, String(localized: "Upload choking algorithm"), \.advanced.uploadChokingAlgorithm),
            expert("peer_turnover", .peersUploading, String(localized: "Peer turnover disconnect percentage"), \.advanced.peerTurnover),
            expert("peer_turnover_cutoff", .peersUploading, String(localized: "Peer turnover threshold percentage"), \.advanced.peerTurnoverCutoff),
            expert("peer_turnover_interval", .peersUploading, String(localized: "Peer turnover disconnect interval"),
                   \.advanced.peerTurnoverInterval),
            expert("request_queue_size", .peersUploading, String(localized: "Maximum outstanding requests to a single peer"),
                   \.advanced.requestQueueSize),
        ]
    }

    private static var expertTrackers: [SettingSpec] {
        [
            expert("announce_to_all_trackers", .trackersAnnouncing, String(localized: "Always announce to all trackers in a tier"),
                   \.advanced.announceToAllTrackers),
            expert("announce_to_all_tiers", .trackersAnnouncing, String(localized: "Always announce to all tiers"), \.advanced.announceToAllTiers),
            expert("announce_ip", .trackersAnnouncing, String(localized: "IP address reported to trackers (requires restart)"),
                   \.advanced.announceIp),
            expert("announce_port", .trackersAnnouncing, String(localized: "Port reported to trackers (requires restart) [0: listening port]"),
                   \.advanced.announcePort),
            expert("max_concurrent_http_announces", .trackersAnnouncing, String(localized: "Max concurrent HTTP announces"),
                   \.advanced.maxConcurrentHttpAnnounces),
            expert("stop_tracker_timeout", .trackersAnnouncing, String(localized: "Stop tracker timeout [0: disabled]"),
                   \.advanced.stopTrackerTimeout),
            expert("dht_bootstrap_nodes", .dht, String(localized: "DHT bootstrap nodes"), \.advanced.dhtBootstrapNodes),
            expert("enable_embedded_tracker", .embeddedTracker, String(localized: "Enable embedded tracker"), \.advanced.enableEmbeddedTracker),
            expert("embedded_tracker_port", .embeddedTracker, String(localized: "Embedded tracker port"), \.advanced.embeddedTrackerPort),
            expert("embedded_tracker_port_forwarding", .embeddedTracker, String(localized: "Enable port forwarding for embedded tracker"),
                   \.advanced.embeddedTrackerPortForwarding),
        ]
    }
}
