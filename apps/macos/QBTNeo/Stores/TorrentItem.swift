import Foundation
import Observation

/// One transfer-list row. Created once per torrent and updated in place from
/// sync diffs; the default columns read their own stored property, so
/// Observation redraws only the cells whose values changed (assignments of
/// equal values do not notify). Other fields come from `info`.
@Observable @MainActor
final class TorrentItem: Identifiable {
    /// Torrent ID (v1 info hash, or truncated v2 hash).
    let id: String

    /// The last record received from the core. Observed, so cells of columns
    /// without their own stored property redraw when the record changes.
    private(set) var info: TorrentInfo

    var name: String
    var size: Int64
    var progress: Double
    var dlSpeed: Int64
    var upSpeed: Int64
    var queuePosition: Int64
    var numSeeds: Int64
    var numComplete: Int64
    var numLeechs: Int64
    var numIncomplete: Int64
    var state: TorrentState
    var eta: Int64
    var category: String
    var tags: [String]
    var ratio: Double
    var availability: Double
    var errorMessage: String

    // Fields without their own column in the default layout are read from the
    // last record instead of being stored a second time on every row.
    var infohashV1: String { info.infohashV1 }
    var infohashV2: String { info.infohashV2 }
    var hasMetadata: Bool { info.hasMetadata }
    var createdBy: String { info.createdBy }
    var creationDate: Int64 { info.creationDate }
    var isPrivate: Bool? { info.private }
    var totalSize: Int64 { info.totalSize }
    var piecesNum: Int64 { info.piecesNum }
    var pieceSize: Int64 { info.pieceSize }
    var magnetURI: String { info.magnetUri }
    var totalWasted: Int64 { info.totalWasted }
    var piecesHave: Int64 { info.piecesHave }
    var sequentialDownload: Bool { info.seqDl }
    var firstLastPiecePriority: Bool { info.fLPiecePrio }
    var superSeeding: Bool { info.superSeeding }
    var forceStart: Bool { info.forceStart }
    var savePath: String { info.savePath }
    var downloadPath: String { info.downloadPath }
    var contentPath: String { info.contentPath }
    var rootPath: String { info.rootPath }
    var addedOn: Int64 { info.addedOn }
    var completionOn: Int64 { info.completionOn }
    var tracker: String { info.tracker }
    var trackersCount: Int64 { info.trackersCount }
    var dlLimit: Int64 { info.dlLimit }
    var upLimit: Int64 { info.upLimit }
    var downloaded: Int64 { info.downloaded }
    var uploaded: Int64 { info.uploaded }
    var downloadedSession: Int64 { info.downloadedSession }
    var uploadedSession: Int64 { info.uploadedSession }
    var amountLeft: Int64 { info.amountLeft }
    var completed: Int64 { info.completed }
    var connectionsCount: Int64 { info.connectionsCount }
    var connectionsLimit: Int64 { info.connectionsLimit }
    var maxRatio: Double { info.maxRatio }
    var maxSeedingTime: Int64 { info.maxSeedingTime }
    var maxInactiveSeedingTime: Int64 { info.maxInactiveSeedingTime }
    var ratioLimit: Double { info.ratioLimit }
    var popularity: Double { info.popularity }
    var seedingTimeLimit: Int64 { info.seedingTimeLimit }
    var inactiveSeedingTimeLimit: Int64 { info.inactiveSeedingTimeLimit }
    var shareLimitAction: ShareLimitAction { info.shareLimitAction }
    var lastSeenComplete: Int64 { info.lastSeenComplete }
    var lastActivity: Int64 { info.lastActivity }
    var autoTMM: Bool { info.autoTmm }
    var timeActive: Int64 { info.timeActive }
    var seedingTime: Int64 { info.seedingTime }
    var reannounce: Int64 { info.reannounce }
    var comment: String { info.comment }
    var hasTrackerWarning: Bool { info.hasTrackerWarning }
    var hasTrackerError: Bool { info.hasTrackerError }
    var hasOtherAnnounceError: Bool { info.hasOtherAnnounceError }

    init(info: TorrentInfo) {
        id = info.hash
        self.info = info
        name = info.name
        size = info.size
        progress = info.progress
        dlSpeed = info.dlSpeed
        upSpeed = info.upSpeed
        queuePosition = info.queuePosition
        numSeeds = info.numSeeds
        numComplete = info.numComplete
        numLeechs = info.numLeechs
        numIncomplete = info.numIncomplete
        state = info.state
        eta = info.eta
        category = info.category
        tags = info.tags
        ratio = info.ratio
        availability = info.availability
        errorMessage = info.errorMessage
    }

    /// Applies a newer record. Returns false (and touches nothing) when the
    /// record is unchanged.
    @discardableResult
    func update(from new: TorrentInfo) -> Bool {
        guard new != info else { return false }
        info = new
        name = new.name
        size = new.size
        progress = new.progress
        dlSpeed = new.dlSpeed
        upSpeed = new.upSpeed
        queuePosition = new.queuePosition
        numSeeds = new.numSeeds
        numComplete = new.numComplete
        numLeechs = new.numLeechs
        numIncomplete = new.numIncomplete
        state = new.state
        eta = new.eta
        category = new.category
        tags = new.tags
        ratio = new.ratio
        availability = new.availability
        errorMessage = new.errorMessage
        return true
    }

    // MARK: Derived values

    var isFinished: Bool { state.isCompleted }

    /// Status column text: errors append the message.
    var statusText: String {
        if state == .error, !errorMessage.isEmpty {
            return String(localized: "\(state.statusText): \(errorMessage)")
        }
        return state.statusText
    }

    /// The folder or file revealed by "Open destination folder".
    var destinationPath: String {
        hasMetadata && !contentPath.isEmpty ? contentPath : savePath
    }

    /// Seconds since the last transfer (`lastActivity` is a timestamp).
    func secondsSinceActivity(now: Int64) -> Int64 {
        lastActivity <= 0 ? -1 : max(now - lastActivity, 0)
    }
}
