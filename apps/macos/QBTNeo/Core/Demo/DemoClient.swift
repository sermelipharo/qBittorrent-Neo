import Foundation
import Synchronization

/// In-process sample session implementing `CoreClient`: ~30 torrents in every
/// state (or 2,000 with `--demo-large`), with trackers, peers, files, pieces
/// and a speed simulation. Used by previews, `--demo` and `--snapshot`.
final class DemoClient: CoreClient {
    private let state: Mutex<DemoState>

    /// - Parameters:
    ///   - large: generate the 2,000-torrent stress data set.
    ///   - animated: advance transfers over time (off for deterministic snapshots).
    init(large: Bool = false, animated: Bool = true) {
        state = Mutex(DemoState(large: large, animated: animated))
    }

    // MARK: Plumbing

    /// Runs a mutation and then delivers the events it produced, outside the lock.
    private func mutate<T>(_ body: (inout DemoState) throws -> T) rethrows -> T {
        let (result, events, listener) = try state.withLock { state -> (T, [CoreEvent], (any EventListener)?) in
            let value = try body(&state)
            return (value, state.takeEvents(), state.listener)
        }
        if let listener {
            for event in events { listener.onEvent(event: event) }
        }
        return result
    }

    private func read<T: Sendable>(_ body: (DemoState) throws -> T) rethrows -> T {
        try state.withLock { try body($0) }
    }

    // MARK: Lifecycle and application

    func setEventListener(listener: any EventListener) {
        state.withLock { $0.listener = listener }
    }

    func shutdown() {}

    func version() -> String { "v0.1.1" }

    func buildInfo() -> BuildInfo {
        BuildInfo(app: "0.1.1", qbittorrentCompat: "5.2.4", webapi: "2.15.1", engine: "Demo session",
                  rustc: "-", platform: "macos", bitness: 64)
    }

    func preferences() -> Preferences { read { $0.preferences } }

    func setPreferences(prefs: Preferences) throws {
        mutate { $0.preferences = prefs; $0.events.append(.preferencesChanged) }
    }

    func defaultSavePath() -> String { read { $0.preferences.downloads.savePath } }

    func freeDiskSpace(path: String) -> Int64 { Int64(412.6 * DemoFactory.gib) }

    // MARK: Transfer list

    func syncMainData() -> MainDataUpdate { mutate { $0.mainData() } }

    func resetMainData() { mutate { $0.resetSync() } }

    // MARK: Properties

    func properties(hash: String) throws -> TorrentProperties {
        let torrent = try read { try $0.torrent(hash) }
        let info = torrent.info
        let active = max(info.timeActive - info.seedingTime, 1)
        return TorrentProperties(
            hash: info.hash, infohashV1: info.infohashV1, infohashV2: info.infohashV2, name: info.name,
            timeElapsed: info.timeActive, seedingTime: info.seedingTime, eta: info.eta,
            connections: info.connectionsCount, connectionsLimit: info.connectionsLimit,
            totalDownloaded: info.downloaded, totalDownloadedSession: info.downloadedSession,
            totalUploaded: info.uploaded, totalUploadedSession: info.uploadedSession,
            dlSpeed: info.dlSpeed, dlSpeedAvg: info.downloaded / active, upSpeed: info.upSpeed,
            upSpeedAvg: info.uploaded / max(info.timeActive, 1), dlLimit: info.dlLimit, upLimit: info.upLimit,
            totalWasted: info.totalWasted, seeds: info.numSeeds, seedsTotal: info.numComplete, peers: info.numLeechs,
            peersTotal: info.numIncomplete, shareRatio: info.ratio, popularity: info.popularity,
            reannounce: info.reannounce, totalSize: info.totalSize, piecesNum: info.piecesNum, pieceSize: info.pieceSize,
            piecesHave: info.piecesHave, createdBy: info.createdBy, lastSeen: info.lastSeenComplete,
            additionDate: info.addedOn, completionDate: info.completionOn, creationDate: info.creationDate,
            savePath: info.savePath, downloadPath: info.downloadPath, comment: info.comment, private: info.private,
            hasMetadata: info.hasMetadata, progress: info.progress, availability: info.availability
        )
    }

    func trackers(hash: String) throws -> [TrackerEntry] {
        try read { state in
            let torrent = try state.torrent(hash)
            let bittorrent = state.preferences.bittorrent
            return DemoPeers.stickyTrackerRows(for: torrent, dht: bittorrent.dht, pex: bittorrent.pex, lsd: bittorrent.lsd)
                + torrent.trackers
        }
    }

    func webSeeds(hash: String) throws -> [WebSeed] {
        try read { try $0.torrent(hash).webSeeds.map(WebSeed.init(url:)) }
    }

    func files(hash: String, indexes: [Int64]) throws -> [TorrentFile] {
        let files = try read { try $0.torrent(hash).files }
        guard !indexes.isEmpty else { return files }
        let wanted = Set(indexes)
        return files.filter { wanted.contains($0.index) }
    }

    func pieceStates(hash: String) throws -> Data {
        try read { Data(try $0.torrent(hash).pieces) }
    }

    func pieceAvailability(hash: String) throws -> [UInt32] {
        try read { state in
            let torrent = try state.torrent(hash)
            guard torrent.isRunning, torrent.info.progress < 1 else { return [] }
            var random = DemoRandom(seed: torrent.seed &+ 99)
            let peers = UInt32(max(torrent.info.numSeeds + torrent.info.numLeechs, 0))
            return torrent.pieces.map { _ in
                peers == 0 ? 0 : UInt32(random.int(0...Int(peers)))
            }
        }
    }

    func peers(hash: String) throws -> [PeerInfo] {
        try read { state in
            let torrent = try state.torrent(hash)
            let time = state.animated ? Date.now.timeIntervalSince1970 - state.startTime : 120
            return DemoPeers.peers(for: torrent, time: time)
        }
    }

    func exportTorrent(hash: String) throws -> Data {
        let name = try read { try $0.torrent(hash).info.name }
        return Data("d8:announce41:udp://tracker.opentrackr.org:1337/announce4:infod4:name\(name.utf8.count):\(name)ee".utf8)
    }

    // MARK: Adding

    func addTorrent(source: TorrentSource, params: AddTorrentParams) async throws -> String {
        try mutate { try $0.addTorrent(source, params: params) }
    }

    func fetchMetadata(source: TorrentSource) async throws -> TorrentMetadataInfo {
        if case .url(let url) = source, url.lowercased().hasPrefix("magnet:") {
            try await Task.sleep(for: .seconds(2))
        }
        let metadata = read { DemoState.sampleMetadata(for: source, existing: $0.torrents) }
        mutate { $0.fetched[metadata.hash] = metadata }
        return metadata
    }

    func saveFetchedMetadata(hash: String) throws -> Data {
        let name = try read { state in
            guard let metadata = state.fetched[hash] else { throw QbtError.NotFound(message: "metadata \(hash)") }
            return metadata.name
        }
        return Data("d4:infod4:name\(name.utf8.count):\(name)ee".utf8)
    }

    // MARK: Torrent actions

    func startTorrents(hashes: [String]) async throws { mutate { $0.start(hashes, forced: false) } }
    func stopTorrents(hashes: [String]) async throws { mutate { $0.stop(hashes) } }

    func setForceStart(hashes: [String], value: Bool) async throws {
        mutate { value ? $0.start(hashes, forced: true) : $0.start(hashes, forced: false) }
    }

    func removeTorrents(hashes: [String], deleteFiles: Bool) async throws { mutate { $0.remove(hashes) } }
    func recheckTorrents(hashes: [String]) async throws { mutate { $0.recheck(hashes) } }

    func reannounceTorrents(hashes: [String]) async throws {
        mutate { state in
            state.update(hashes) { torrent in
                torrent.info.reannounce = 1_800
                for index in torrent.trackers.indices { torrent.trackers[index].nextAnnounce = 1_800 }
            }
        }
    }

    func setLocation(hashes: [String], location: String) async throws { mutate { $0.setLocation(hashes, path: location) } }
    func setSavePath(hashes: [String], path: String) async throws { mutate { $0.setLocation(hashes, path: path) } }

    func setDownloadPath(hashes: [String], path: String) async throws {
        mutate { $0.update(hashes) { $0.info.downloadPath = path } }
    }

    func renameTorrent(hash: String, name: String) throws { mutate { $0.update([hash]) { $0.info.name = name } } }

    func renameFile(hash: String, oldPath: String, newPath: String) async throws {
        try mutate { try $0.renameFile(hash, old: oldPath, new: newPath, folder: false) }
    }

    func renameFolder(hash: String, oldPath: String, newPath: String) async throws {
        try mutate { try $0.renameFile(hash, old: oldPath, new: newPath, folder: true) }
    }

    func setFilePriority(hash: String, indexes: [Int64], priority: FilePriority) throws {
        let wanted = Set(indexes)
        mutate { state in
            state.update([hash]) { torrent in
                for index in torrent.files.indices where wanted.contains(torrent.files[index].index) {
                    torrent.files[index].priority = priority
                }
                torrent.info.size = torrent.files.filter { $0.priority != .ignored }.reduce(0) { $0 + $1.size }
            }
        }
    }

    func setAutoManagement(hashes: [String], enabled: Bool) throws { mutate { $0.update(hashes) { $0.info.autoTmm = enabled } } }
    func setDownloadLimit(hashes: [String], limit: Int64) throws { mutate { $0.update(hashes) { $0.info.dlLimit = max(limit, 0) } } }
    func setUploadLimit(hashes: [String], limit: Int64) throws { mutate { $0.update(hashes) { $0.info.upLimit = max(limit, 0) } } }

    func setShareLimits(
        hashes: [String], ratioLimit: Double, seedingTimeLimit: Int64, inactiveSeedingTimeLimit: Int64, action: ShareLimitAction
    ) throws {
        mutate { state in
            let global = state.preferences.bittorrent
            state.update(hashes) { torrent in
                torrent.info.ratioLimit = ratioLimit
                torrent.info.seedingTimeLimit = seedingTimeLimit
                torrent.info.inactiveSeedingTimeLimit = inactiveSeedingTimeLimit
                torrent.info.shareLimitAction = action
                torrent.info.maxRatio = ratioLimit == -2 ? global.maxRatio : ratioLimit
                torrent.info.maxSeedingTime = seedingTimeLimit == -2 ? global.maxSeedingTime : seedingTimeLimit
                torrent.info.maxInactiveSeedingTime = inactiveSeedingTimeLimit == -2 ? global.maxInactiveSeedingTime : inactiveSeedingTimeLimit
            }
        }
    }

    func setSuperSeeding(hashes: [String], value: Bool) throws { mutate { $0.update(hashes) { $0.info.superSeeding = value } } }
    func setSequentialDownload(hashes: [String], value: Bool) throws { mutate { $0.update(hashes) { $0.info.seqDl = value } } }
    func setFirstLastPiecePriority(hashes: [String], value: Bool) throws { mutate { $0.update(hashes) { $0.info.fLPiecePrio = value } } }
    func discoveryOptions(hashes: [String]) -> [TorrentDiscoveryOptions] {
        read { state in
            hashes.compactMap { try? state.torrent($0) }.map {
                TorrentDiscoveryOptions(hash: $0.info.hash, private: $0.info.private ?? false,
                                        disableDht: false, disablePex: false, disableLsd: false)
            }
        }
    }

    func setDhtDisabled(hashes: [String], value: Bool) throws {}
    func setPexDisabled(hashes: [String], value: Bool) throws {}
    func setLsdDisabled(hashes: [String], value: Bool) throws {}
    func queueIncrease(hashes: [String]) throws { mutate { $0.moveQueue(hashes, .up) } }
    func queueDecrease(hashes: [String]) throws { mutate { $0.moveQueue(hashes, .down) } }
    func queueTop(hashes: [String]) throws { mutate { $0.moveQueue(hashes, .top) } }
    func queueBottom(hashes: [String]) throws { mutate { $0.moveQueue(hashes, .bottom) } }

    // MARK: Trackers, peers, web seeds

    func addTrackers(hash: String, trackers: [TrackerTierEntry]) throws { mutate { $0.addTrackers(hash, trackers) } }

    func editTracker(hash: String, origUrl: String, newUrl: String) throws {
        try mutate { state in
            let torrent = try state.torrent(hash)
            if torrent.trackers.contains(where: { $0.url == newUrl }) {
                throw QbtError.Conflict(message: "The tracker URL already exists.")
            }
            state.update([hash]) { torrent in
                for index in torrent.trackers.indices where torrent.trackers[index].url == origUrl {
                    torrent.trackers[index].url = newUrl
                }
            }
        }
    }

    func removeTrackers(hash: String, urls: [String]) throws {
        mutate { state in
            state.update([hash]) { torrent in
                torrent.trackers.removeAll { urls.contains($0.url) }
                torrent.info.trackersCount = Int64(torrent.trackers.count)
            }
        }
    }

    func replaceTrackers(hash: String, trackers: [TrackerTierEntry]) throws { mutate { $0.replaceTrackers(hash, trackers) } }

    func addPeers(hashes: [String], peers: [String]) throws {
        mutate { state in
            for peer in peers { state.appendLog(.info, "Peer \"\(peer)\" is added to torrent \"\(hashes.first ?? "")\"") }
        }
    }

    func banPeers(peers: [String]) throws {
        mutate { state in
            state.preferences.connection.bannedIps.append(contentsOf: peers)
            for peer in peers { state.appendLog(.info, "Peer \"\(peer)\" is manually banned") }
        }
    }

    func addWebSeeds(hash: String, urls: [String]) throws {
        mutate { $0.update([hash]) { $0.webSeeds.append(contentsOf: urls) } }
    }

    func editWebSeed(hash: String, origUrl: String, newUrl: String) throws {
        mutate { $0.update([hash]) { torrent in torrent.webSeeds = torrent.webSeeds.map { $0 == origUrl ? newUrl : $0 } } }
    }

    func removeWebSeeds(hash: String, urls: [String]) throws {
        mutate { $0.update([hash]) { $0.webSeeds.removeAll { urls.contains($0) } } }
    }

    // MARK: Categories and tags

    func categories() -> [Category] { read { Array($0.categories.values) } }
    func createCategory(category: Category) throws { try mutate { try $0.createCategory(category) } }
    func editCategory(category: Category) throws { mutate { $0.categories[category.name] = category } }
    func removeCategories(names: [String]) throws { mutate { $0.removeCategories(names) } }
    func setCategory(hashes: [String], category: String) throws { mutate { $0.setCategory(hashes, category) } }
    func tags() -> [String] { read { Array($0.tags) } }
    func createTags(tags: [String]) throws { mutate { $0.tags.formUnion(tags) } }
    func deleteTags(tags: [String]) throws { mutate { $0.deleteTags(tags) } }
    func addTags(hashes: [String], tags: [String]) throws { mutate { $0.addTags(hashes, tags) } }
    func removeTags(hashes: [String], tags: [String]) throws { mutate { $0.removeTags(hashes, tags) } }

    // MARK: Global transfer state

    func serverState() -> ServerState {
        mutate { state in
            state.step(now: Date.now.timeIntervalSince1970)
            return state.serverState()
        }
    }

    func altSpeedLimitsEnabled() -> Bool { read { $0.altSpeed } }
    func setAltSpeedLimitsEnabled(enabled: Bool) { mutate { $0.altSpeed = enabled } }

    func globalDownloadLimit() -> Int64 { read { $0.effectiveLimits().down } }

    func setGlobalDownloadLimit(limit: Int64) throws {
        mutate { state in
            if state.altSpeed { state.preferences.speed.altDlLimit = limit } else { state.preferences.speed.dlLimit = limit }
        }
    }

    func globalUploadLimit() -> Int64 { read { $0.effectiveLimits().up } }

    func setGlobalUploadLimit(limit: Int64) throws {
        mutate { state in
            if state.altSpeed { state.preferences.speed.altUpLimit = limit } else { state.preferences.speed.upLimit = limit }
        }
    }

    func speedHistory(seconds: UInt32) -> [SpeedSample] { read { $0.speedHistory(seconds: seconds) } }

    // MARK: Log

    func mainLog(lastKnownId: Int64, levels: [LogLevel]) -> [LogMessage] {
        read { state in
            state.log.filter { $0.id > lastKnownId && (levels.isEmpty || levels.contains($0.level)) }
        }
    }

    func peerLog(lastKnownId: Int64) -> [PeerLogEntry] { [] }

    func clearLog() { mutate { $0.log.removeAll() } }
}
