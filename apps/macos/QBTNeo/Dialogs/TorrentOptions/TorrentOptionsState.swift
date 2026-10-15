import Foundation

/// Editable values of the Torrent Options dialog for one or more torrents;
/// mixed values stay untouched on OK unless edited (features.md §3.10).
struct TorrentOptionsState: Equatable {
    var autoTMM: [Bool] = []
    var savePath = ""
    var useDownloadPath: [Bool] = []
    var downloadPath = ""
    /// nil = categories differ ("keep each torrent's category").
    var category: String?
    /// bytes/s; -1 = mixed.
    var downloadLimit: Int64 = 0
    var uploadLimit: Int64 = 0
    var shareLimits = ShareLimits()
    var sequential: [Bool] = []
    var firstLast: [Bool] = []
    /// Discovery switches of the public torrents only (private ones never use them).
    var disableDHT: [Bool] = []
    var disablePeX: [Bool] = []
    var disableLSD: [Bool] = []
    /// Every selected torrent is private: the switches show checked and locked.
    var allPrivate = false

    @MainActor
    init(items: [TorrentItem] = [], discovery: [TorrentDiscoveryOptions] = []) {
        guard let first = items.first else { return }
        autoTMM = items.map(\.autoTMM)
        savePath = items.allSatisfy { $0.savePath == first.savePath } ? first.savePath : ""
        useDownloadPath = items.map { !$0.downloadPath.isEmpty }
        downloadPath = items.allSatisfy { $0.downloadPath == first.downloadPath } ? first.downloadPath : ""
        category = items.allSatisfy { $0.category == first.category } ? first.category : nil
        downloadLimit = items.allSatisfy { $0.dlLimit == first.dlLimit } ? max(first.dlLimit, 0) : -1
        uploadLimit = items.allSatisfy { $0.upLimit == first.upLimit } ? max(first.upLimit, 0) : -1
        shareLimits = ShareLimits(ratio: first.ratioLimit, seedingMinutes: first.seedingTimeLimit,
                                  inactiveMinutes: first.inactiveSeedingTimeLimit, action: first.shareLimitAction)
        sequential = items.map(\.sequentialDownload)
        firstLast = items.map(\.firstLastPiecePriority)
        let publicTorrents = discovery.filter { !$0.private }
        allPrivate = !discovery.isEmpty && publicTorrents.isEmpty
        guard !allPrivate else {
            (disableDHT, disablePeX, disableLSD) = ([true], [true], [true])
            return
        }
        disableDHT = publicTorrents.map(\.disableDht)
        disablePeX = publicTorrents.map(\.disablePex)
        disableLSD = publicTorrents.map(\.disableLsd)
    }

    static func uniform(_ values: [Bool]) -> Bool? {
        guard let first = values.first, values.allSatisfy({ $0 == first }) else { return nil }
        return first
    }
}
