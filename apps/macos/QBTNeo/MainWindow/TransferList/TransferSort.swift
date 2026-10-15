import Foundation

/// Sort comparator for the transfer list, keyed by column so it stays
/// `Sendable` (key paths into main-actor rows are not). The table only stores
/// these values; `TransferListModel` performs the sort on the main actor.
struct TransferSort: SortComparator, Hashable, Codable, Sendable {
    var column: TransferColumn
    var order: SortOrder = .forward

    init(_ column: TransferColumn, order: SortOrder = .forward) {
        self.column = column
        self.order = order
    }

    func compare(_ lhs: TorrentItem, _ rhs: TorrentItem) -> ComparisonResult {
        MainActor.assumeIsolated {
            let result = Self.compareAscending(column, lhs, rhs)
            return order == .forward ? result : result.reversed
        }
    }

    /// Ascending comparison by the column's underlying value (not its text).
    /// Invalid (negative/unknown) values sort after valid ones.
    @MainActor
    static func compareAscending(_ column: TransferColumn, _ lhs: TorrentItem, _ rhs: TorrentItem) -> ComparisonResult {
        switch column {
        case .queuePosition: validFirst(lhs.queuePosition, rhs.queuePosition, isValid: { $0 > 0 })
        case .name: lhs.name.localizedStandardCompare(rhs.name)
        case .size: value(lhs.size, rhs.size)
        case .totalSize: value(lhs.totalSize, rhs.totalSize)
        case .progress: value(lhs.progress, rhs.progress)
        case .status: value(stateRank(lhs.state), stateRank(rhs.state))
        case .seeds: value(lhs.numSeeds, rhs.numSeeds).then(value(lhs.numComplete, rhs.numComplete))
        case .peers: value(lhs.numLeechs, rhs.numLeechs).then(value(lhs.numIncomplete, rhs.numIncomplete))
        case .downSpeed: value(lhs.dlSpeed, rhs.dlSpeed)
        case .upSpeed: value(lhs.upSpeed, rhs.upSpeed)
        case .eta: value(lhs.eta < 0 ? Int64.max : lhs.eta, rhs.eta < 0 ? Int64.max : rhs.eta)
        case .ratio: value(infiniteRatio(lhs.ratio), infiniteRatio(rhs.ratio))
        case .popularity: value(infiniteRatio(lhs.popularity), infiniteRatio(rhs.popularity))
        case .category: lhs.category.localizedStandardCompare(rhs.category)
        case .tags: compareTags(lhs.tags, rhs.tags)
        case .addedOn: validFirst(lhs.addedOn, rhs.addedOn, isValid: { $0 > 0 })
        case .completedOn: validFirst(lhs.completionOn, rhs.completionOn, isValid: { $0 > 0 })
        case .tracker: lhs.tracker.localizedStandardCompare(rhs.tracker)
        case .downLimit: value(unlimited(lhs.dlLimit), unlimited(rhs.dlLimit))
        case .upLimit: value(unlimited(lhs.upLimit), unlimited(rhs.upLimit))
        case .downloaded: value(lhs.downloaded, rhs.downloaded)
        case .uploaded: value(lhs.uploaded, rhs.uploaded)
        case .sessionDownloaded: value(lhs.downloadedSession, rhs.downloadedSession)
        case .sessionUploaded: value(lhs.uploadedSession, rhs.uploadedSession)
        case .remaining: value(lhs.amountLeft, rhs.amountLeft)
        case .timeActive: value(lhs.timeActive, rhs.timeActive)
        case .savePath: lhs.savePath.localizedStandardCompare(rhs.savePath)
        case .completed: value(lhs.completed, rhs.completed)
        case .ratioLimit: value(infiniteRatio(lhs.maxRatio), infiniteRatio(rhs.maxRatio))
        case .lastSeenComplete: validFirst(lhs.lastSeenComplete, rhs.lastSeenComplete, isValid: { $0 > 0 })
        case .lastActivity: validFirst(-lhs.lastActivity, -rhs.lastActivity, isValid: { $0 < 0 })
        case .availability: validFirst(lhs.availability, rhs.availability, isValid: { $0 >= 0 })
        case .incompletePath: lhs.downloadPath.localizedStandardCompare(rhs.downloadPath)
        case .infohashV1: validFirst(lhs.infohashV1, rhs.infohashV1, isValid: { !$0.isEmpty })
        case .infohashV2: validFirst(lhs.infohashV2, rhs.infohashV2, isValid: { !$0.isEmpty })
        case .reannounceIn: value(lhs.reannounce, rhs.reannounce)
        case .isPrivate: validFirst(lhs.isPrivate.map { $0 ? 1 : 0 } ?? -1, rhs.isPrivate.map { $0 ? 1 : 0 } ?? -1, isValid: { $0 >= 0 })
        case .createdOn: validFirst(lhs.creationDate, rhs.creationDate, isValid: { $0 > 0 })
        }
    }

    private static func value<T: Comparable>(_ lhs: T, _ rhs: T) -> ComparisonResult {
        lhs < rhs ? .orderedAscending : (lhs == rhs ? .orderedSame : .orderedDescending)
    }

    private static func validFirst<T: Comparable>(_ lhs: T, _ rhs: T, isValid: (T) -> Bool) -> ComparisonResult {
        switch (isValid(lhs), isValid(rhs)) {
        case (true, true): value(lhs, rhs)
        case (true, false): .orderedAscending
        case (false, true): .orderedDescending
        case (false, false): .orderedSame
        }
    }

    private static func infiniteRatio(_ ratio: Double) -> Double {
        ratio < 0 || ratio >= ValueFormatter.maxRatio ? .infinity : ratio
    }

    private static func unlimited(_ limit: Int64) -> Int64 {
        limit > 0 ? limit : .max
    }

    private static func stateRank(_ state: TorrentState) -> Int {
        switch state {
        case .unknown: -1
        case .forcedDownloading: 0
        case .downloading: 1
        case .forcedDownloadingMetadata: 2
        case .downloadingMetadata: 3
        case .stalledDownloading: 4
        case .forcedUploading: 5
        case .uploading: 6
        case .stalledUploading: 7
        case .checkingResumeData: 8
        case .queuedDownloading: 9
        case .queuedUploading: 10
        case .checkingUploading: 11
        case .checkingDownloading: 12
        case .stoppedDownloading: 13
        case .stoppedUploading: 14
        case .moving: 15
        case .missingFiles: 16
        case .error: 17
        }
    }

    private static func compareTags(_ lhs: [String], _ rhs: [String]) -> ComparisonResult {
        for (left, right) in zip(lhs, rhs) {
            let result = left.localizedStandardCompare(right)
            if result != .orderedSame { return result }
        }
        return value(lhs.count, rhs.count)
    }
}

extension ComparisonResult {
    var reversed: ComparisonResult {
        switch self {
        case .orderedAscending: .orderedDescending
        case .orderedDescending: .orderedAscending
        case .orderedSame: .orderedSame
        }
    }

    /// Lexicographic tie-break.
    func then(_ next: @autoclosure () -> ComparisonResult) -> ComparisonResult {
        self == .orderedSame ? next() : self
    }
}
