import Foundation

// Empty records to start from when building demo data (the generated
// memberwise initializers have no defaults).

extension TorrentInfo {
    static func blank(hash: String) -> TorrentInfo {
        TorrentInfo(
            hash: hash, infohashV1: hash, infohashV2: "", name: "", hasMetadata: true, createdBy: "",
            creationDate: 0, private: false, totalSize: 0, piecesNum: 0, pieceSize: 0, magnetUri: "", size: 0,
            progress: 0, totalWasted: 0, piecesHave: 0, dlSpeed: 0, upSpeed: 0, queuePosition: 0, numSeeds: 0,
            numComplete: -1, numLeechs: 0, numIncomplete: -1, state: .stoppedDownloading, eta: 8_640_000,
            seqDl: false, fLPiecePrio: false, category: "", tags: [], superSeeding: false, forceStart: false,
            savePath: "", downloadPath: "", contentPath: "", rootPath: "", addedOn: 0, completionOn: 0, tracker: "",
            trackersCount: 0, dlLimit: 0, upLimit: 0, downloaded: 0, uploaded: 0, downloadedSession: 0,
            uploadedSession: 0, amountLeft: 0, completed: 0, connectionsCount: 0, connectionsLimit: 100,
            maxRatio: -1, maxSeedingTime: -1, maxInactiveSeedingTime: -1, ratio: 0, ratioLimit: -2, popularity: 0,
            seedingTimeLimit: -2, inactiveSeedingTimeLimit: -2, shareLimitAction: .default, lastSeenComplete: 0,
            lastActivity: 0, autoTmm: false, timeActive: 0, seedingTime: 0, availability: -1, reannounce: 0,
            comment: "", hasTrackerWarning: false, hasTrackerError: false, hasOtherAnnounceError: false,
            errorMessage: ""
        )
    }
}

extension ServerState {
    static let blank = ServerState(
        dlSpeed: 0, dlSessionData: 0, upSpeed: 0, upSessionData: 0, dlRateLimit: 0, upRateLimit: 0, dhtNodes: 0,
        connectionStatus: .disconnected, queueing: false, useAltSpeedLimits: false, useSubcategories: false,
        refreshInterval: 1500, freeSpaceOnDisk: -1, lastExternalAddressV4: "", lastExternalAddressV6: "",
        alltimeDownload: 0, alltimeUpload: 0, totalWastedSession: 0, globalRatio: 0, totalPeerConnections: 0,
        readCacheHits: 0, totalBuffersSize: 0, writeCacheOverload: 0, readCacheOverload: 0, queuedIoJobs: 0,
        averageTimeQueue: 0, totalQueuedSize: 0
    )
}

extension AddTorrentParams {
    /// Every field unset: the session defaults apply.
    static let sessionDefaults = AddTorrentParams(
        name: nil, category: nil, tags: [], savePath: nil, useDownloadPath: nil, downloadPath: nil, autoTmm: nil,
        stopped: nil, stopCondition: nil, skipChecking: false, addToQueueTop: nil, contentLayout: nil,
        sequential: false, firstLastPiecePriority: false, forced: false, downloadLimit: nil, uploadLimit: nil,
        ratioLimit: nil, seedingTimeLimit: nil, inactiveSeedingTimeLimit: nil, shareLimitAction: nil,
        filePriorities: [], filePaths: [], trackers: [], urlSeeds: [], cookie: nil
    )
}

extension TorrentParamsTemplate {
    /// Every field at "Default".
    static let defaults = TorrentParamsTemplate(
        category: "", tags: [], savePath: "", useDownloadPath: nil, downloadPath: "", autoTmm: nil, stopped: nil,
        stopCondition: nil, skipChecking: false, addToQueueTop: nil, contentLayout: nil, uploadLimit: -1,
        downloadLimit: -1, ratioLimit: -2, seedingTimeLimit: -2, inactiveSeedingTimeLimit: -2
    )
}

extension Category {
    /// A category with the given share limits (default: inherit from parent / global).
    init(name: String, savePath: String, downloadPath: CategoryDownloadPath, shareLimits: ShareLimits = ShareLimits()) {
        self.init(
            name: name, savePath: savePath, downloadPath: downloadPath, ratioLimit: shareLimits.ratio,
            seedingTimeLimit: shareLimits.seedingMinutes, inactiveSeedingTimeLimit: shareLimits.inactiveMinutes,
            shareLimitAction: shareLimits.action
        )
    }

    var shareLimits: ShareLimits {
        ShareLimits(ratio: ratioLimit, seedingMinutes: seedingTimeLimit, inactiveMinutes: inactiveSeedingTimeLimit, action: shareLimitAction)
    }
}
