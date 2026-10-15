import Foundation

/// Writable views of preference values in the units and shapes the pages
/// show (KiB/s instead of bytes/s, checkbox + value pairs for "-1 =
/// disabled", times as dates, lists as text).
extension PreferencesModel {
    // MARK: Speed (bytes/s in the core, KiB/s in the GUI)

    var downloadLimitKiB: Int64 {
        get { draft.speed.dlLimit / 1_024 }
        set { draft.speed.dlLimit = newValue * 1_024 }
    }

    var uploadLimitKiB: Int64 {
        get { draft.speed.upLimit / 1_024 }
        set { draft.speed.upLimit = newValue * 1_024 }
    }

    var altDownloadLimitKiB: Int64 {
        get { draft.speed.altDlLimit / 1_024 }
        set { draft.speed.altDlLimit = newValue * 1_024 }
    }

    var altUploadLimitKiB: Int64 {
        get { draft.speed.altUpLimit / 1_024 }
        set { draft.speed.altUpLimit = newValue * 1_024 }
    }

    var scheduleFrom: Date {
        get { Self.time(hour: draft.speed.scheduleFromHour, minute: draft.speed.scheduleFromMin) }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            draft.speed.scheduleFromHour = Int64(parts.hour ?? 0)
            draft.speed.scheduleFromMin = Int64(parts.minute ?? 0)
        }
    }

    var scheduleTo: Date {
        get { Self.time(hour: draft.speed.scheduleToHour, minute: draft.speed.scheduleToMin) }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            draft.speed.scheduleToHour = Int64(parts.hour ?? 0)
            draft.speed.scheduleToMin = Int64(parts.minute ?? 0)
        }
    }

    private static func time(hour: Int64, minute: Int64) -> Date {
        Calendar.current.date(bySettingHour: Int(hour), minute: Int(minute), second: 0, of: .now) ?? .now
    }

    // MARK: Behavior

    /// "Delete .torrent files afterwards" group.
    var deletesTorrentFiles: Bool {
        get { draft.downloads.autoDeleteMode != .never }
        set { draft.downloads.autoDeleteMode = newValue ? .ifAdded : .never }
    }

    /// "Also when addition is cancelled".
    var deletesCancelledTorrentFiles: Bool {
        get { draft.downloads.autoDeleteMode == .always }
        set { draft.downloads.autoDeleteMode = newValue ? .always : (deletesTorrentFiles ? .ifAdded : .never) }
    }

    // MARK: Downloads

    var excludedFileNamesText: String {
        get { draft.downloads.excludedFileNames.joined(separator: "\n") }
        set { draft.downloads.excludedFileNames = Self.lines(newValue) }
    }

    var exportDirectoryEnabled: Bool {
        get { exportDirChecked }
        set {
            exportDirChecked = newValue
            if newValue {
                draft.downloads.exportDir = rememberedPaths["exportDir"] ?? ""
            } else {
                rememberedPaths["exportDir"] = draft.downloads.exportDir
                draft.downloads.exportDir = ""
            }
        }
    }

    var finishedExportDirectoryEnabled: Bool {
        get { finishedExportDirChecked }
        set {
            finishedExportDirChecked = newValue
            if newValue {
                draft.downloads.exportDirFin = rememberedPaths["exportDirFin"] ?? ""
            } else {
                rememberedPaths["exportDirFin"] = draft.downloads.exportDirFin
                draft.downloads.exportDirFin = ""
            }
        }
    }

    // MARK: Connection ("-1 = unlimited" behind a checkbox)

    var maxConnectionsEnabled: Bool {
        get { draft.connection.maxConnec > 0 }
        set { toggleLimit(\.connection.maxConnec, enabled: newValue, fallback: 500) }
    }

    var maxConnections: Int64 {
        get { shownLimit(\.connection.maxConnec, fallback: 500) }
        set { draft.connection.maxConnec = newValue }
    }

    var maxConnectionsPerTorrentEnabled: Bool {
        get { draft.connection.maxConnecPerTorrent > 0 }
        set { toggleLimit(\.connection.maxConnecPerTorrent, enabled: newValue, fallback: 100) }
    }

    var maxConnectionsPerTorrent: Int64 {
        get { shownLimit(\.connection.maxConnecPerTorrent, fallback: 100) }
        set { draft.connection.maxConnecPerTorrent = newValue }
    }

    var maxUploadsEnabled: Bool {
        get { draft.connection.maxUploads > 0 }
        set { toggleLimit(\.connection.maxUploads, enabled: newValue, fallback: 20) }
    }

    var maxUploads: Int64 {
        get { shownLimit(\.connection.maxUploads, fallback: 20) }
        set { draft.connection.maxUploads = newValue }
    }

    var maxUploadsPerTorrentEnabled: Bool {
        get { draft.connection.maxUploadsPerTorrent > 0 }
        set { toggleLimit(\.connection.maxUploadsPerTorrent, enabled: newValue, fallback: 4) }
    }

    var maxUploadsPerTorrent: Int64 {
        get { shownLimit(\.connection.maxUploadsPerTorrent, fallback: 4) }
        set { draft.connection.maxUploadsPerTorrent = newValue }
    }

    // MARK: BitTorrent seeding limits

    var maxRatioEnabled: Bool {
        get { draft.bittorrent.maxRatio >= 0 }
        set {
            if newValue {
                draft.bittorrent.maxRatio = rememberedRatio ?? 1
            } else {
                if draft.bittorrent.maxRatio >= 0 { rememberedRatio = draft.bittorrent.maxRatio }
                draft.bittorrent.maxRatio = -1
            }
        }
    }

    var maxRatio: Double {
        get { draft.bittorrent.maxRatio >= 0 ? draft.bittorrent.maxRatio : rememberedRatio ?? 1 }
        set { draft.bittorrent.maxRatio = max(newValue, 0) }
    }

    var maxSeedingTimeEnabled: Bool {
        get { draft.bittorrent.maxSeedingTime >= 0 }
        set { toggleLimit(\.bittorrent.maxSeedingTime, enabled: newValue, fallback: 1_440, minimum: 0) }
    }

    var maxSeedingTime: Int64 {
        get { shownLimit(\.bittorrent.maxSeedingTime, fallback: 1_440, minimum: 0) }
        set { draft.bittorrent.maxSeedingTime = newValue }
    }

    var maxInactiveSeedingTimeEnabled: Bool {
        get { draft.bittorrent.maxInactiveSeedingTime >= 0 }
        set { toggleLimit(\.bittorrent.maxInactiveSeedingTime, enabled: newValue, fallback: 1_440, minimum: 0) }
    }

    var maxInactiveSeedingTime: Int64 {
        get { shownLimit(\.bittorrent.maxInactiveSeedingTime, fallback: 1_440, minimum: 0) }
        set { draft.bittorrent.maxInactiveSeedingTime = newValue }
    }

    var anySeedingLimitEnabled: Bool { maxRatioEnabled || maxSeedingTimeEnabled || maxInactiveSeedingTimeEnabled }

    // MARK: RSS

    var smartEpisodeFiltersText: String {
        get { draft.rss.rssSmartEpisodeFilters.joined(separator: "\n") }
        set { draft.rss.rssSmartEpisodeFilters = Self.lines(newValue) }
    }

    // MARK: Advanced (bytes in the core, KiB/MiB in the GUI)

    var torrentFileSizeLimitMiB: Int64 {
        get { draft.advanced.torrentFileSizeLimit / (1_024 * 1_024) }
        set { draft.advanced.torrentFileSizeLimit = newValue * 1_024 * 1_024 }
    }

    var diskQueueSizeKiB: Int64 {
        get { draft.advanced.diskQueueSize / 1_024 }
        set { draft.advanced.diskQueueSize = newValue * 1_024 }
    }

    var socketSendBufferKiB: Int64 {
        get { draft.advanced.socketSendBufferSize / 1_024 }
        set { draft.advanced.socketSendBufferSize = newValue * 1_024 }
    }

    var socketReceiveBufferKiB: Int64 {
        get { draft.advanced.socketReceiveBufferSize / 1_024 }
        set { draft.advanced.socketReceiveBufferSize = newValue * 1_024 }
    }

    // MARK: Helpers

    /// Non-empty, trimmed lines (the GUI drops empty entries).
    static func lines(_ text: String) -> [String] {
        text.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func toggleLimit(_ path: WritableKeyPath<Preferences, Int64>, enabled: Bool, fallback: Int64, minimum: Int64 = 1) {
        let key = "\(path)"
        if enabled {
            draft[keyPath: path] = remembered[key] ?? fallback
        } else {
            if draft[keyPath: path] >= minimum { remembered[key] = draft[keyPath: path] }
            draft[keyPath: path] = -1
        }
    }

    private func shownLimit(_ path: WritableKeyPath<Preferences, Int64>, fallback: Int64, minimum: Int64 = 1) -> Int64 {
        draft[keyPath: path] >= minimum ? draft[keyPath: path] : remembered["\(path)"] ?? fallback
    }
}
