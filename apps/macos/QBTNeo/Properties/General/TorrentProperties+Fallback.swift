import Foundation

extension TorrentProperties {
    /// General-tab values derived from the transfer-list row, used until (or
    /// when) the core cannot provide the properties record.
    @MainActor
    init(item: TorrentItem) {
        let downloadTime = max(item.timeActive - item.seedingTime, 0)
        self.init(
            hash: item.id, infohashV1: item.infohashV1, infohashV2: item.infohashV2, name: item.name,
            timeElapsed: item.timeActive, seedingTime: item.seedingTime, eta: item.eta,
            connections: item.connectionsCount, connectionsLimit: item.connectionsLimit,
            totalDownloaded: item.downloaded, totalDownloadedSession: item.downloadedSession,
            totalUploaded: item.uploaded, totalUploadedSession: item.uploadedSession,
            dlSpeed: item.dlSpeed, dlSpeedAvg: downloadTime > 0 ? item.downloaded / downloadTime : -1,
            upSpeed: item.upSpeed, upSpeedAvg: item.timeActive > 0 ? item.uploaded / item.timeActive : -1,
            dlLimit: item.dlLimit, upLimit: item.upLimit, totalWasted: item.totalWasted,
            seeds: item.numSeeds, seedsTotal: item.numComplete, peers: item.numLeechs, peersTotal: item.numIncomplete,
            shareRatio: item.ratio, popularity: item.popularity, reannounce: item.reannounce,
            totalSize: item.totalSize, piecesNum: item.piecesNum, pieceSize: item.pieceSize,
            piecesHave: item.piecesHave, createdBy: item.createdBy, lastSeen: item.lastSeenComplete,
            additionDate: item.addedOn, completionDate: item.completionOn, creationDate: item.creationDate,
            savePath: item.savePath, downloadPath: item.downloadPath, comment: item.comment,
            private: item.isPrivate, hasMetadata: item.hasMetadata, progress: item.progress,
            availability: item.availability
        )
    }
}
