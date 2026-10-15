import Foundation

/// The calls the GUI makes into the core, so views and models can run against
/// qBittorrent's C++ core (`QtCoreClient`) or `DemoClient` (previews,
/// `--demo`, `--snapshot`).
///
/// Rules: sync methods are in-memory and cheap but may still allocate large
/// arrays, so models call the bulky ones (`syncMainData`, `files`, `peers`)
/// through `CoreCall.run` off the main actor. Never call the client from `body`.
///
/// Windows built later (RSS, Search, Creator, Statistics, Log, Preferences)
/// add the calls they need here and in `DemoClient`.
protocol CoreClient: AnyObject, Sendable {
    // MARK: Lifecycle and application
    func setEventListener(listener: any EventListener)
    func shutdown()
    func version() -> String
    func buildInfo() -> BuildInfo
    func preferences() -> Preferences
    func setPreferences(prefs: Preferences) throws
    func defaultSavePath() -> String
    func freeDiskSpace(path: String) -> Int64

    // MARK: Transfer list
    func syncMainData() -> MainDataUpdate
    func resetMainData()

    // MARK: Properties tabs
    func properties(hash: String) throws -> TorrentProperties
    func trackers(hash: String) throws -> [TrackerEntry]
    func webSeeds(hash: String) throws -> [WebSeed]
    func files(hash: String, indexes: [Int64]) throws -> [TorrentFile]
    func pieceStates(hash: String) throws -> Data
    func pieceAvailability(hash: String) throws -> [UInt32]
    func peers(hash: String) throws -> [PeerInfo]
    func exportTorrent(hash: String) throws -> Data

    // MARK: Adding
    func addTorrent(source: TorrentSource, params: AddTorrentParams) async throws -> String
    func fetchMetadata(source: TorrentSource) async throws -> TorrentMetadataInfo
    func saveFetchedMetadata(hash: String) throws -> Data

    // MARK: Torrent actions
    func startTorrents(hashes: [String]) async throws
    func stopTorrents(hashes: [String]) async throws
    func setForceStart(hashes: [String], value: Bool) async throws
    func removeTorrents(hashes: [String], deleteFiles: Bool) async throws
    func recheckTorrents(hashes: [String]) async throws
    func reannounceTorrents(hashes: [String]) async throws
    func setLocation(hashes: [String], location: String) async throws
    func setSavePath(hashes: [String], path: String) async throws
    func setDownloadPath(hashes: [String], path: String) async throws
    func renameTorrent(hash: String, name: String) throws
    func renameFile(hash: String, oldPath: String, newPath: String) async throws
    func renameFolder(hash: String, oldPath: String, newPath: String) async throws
    func setFilePriority(hash: String, indexes: [Int64], priority: FilePriority) throws
    func setAutoManagement(hashes: [String], enabled: Bool) throws
    func setDownloadLimit(hashes: [String], limit: Int64) throws
    func setUploadLimit(hashes: [String], limit: Int64) throws
    func setShareLimits(
        hashes: [String],
        ratioLimit: Double,
        seedingTimeLimit: Int64,
        inactiveSeedingTimeLimit: Int64,
        action: ShareLimitAction
    ) throws
    func setSuperSeeding(hashes: [String], value: Bool) throws
    func setSequentialDownload(hashes: [String], value: Bool) throws
    func setFirstLastPiecePriority(hashes: [String], value: Bool) throws
    func discoveryOptions(hashes: [String]) -> [TorrentDiscoveryOptions]
    func setDhtDisabled(hashes: [String], value: Bool) throws
    func setPexDisabled(hashes: [String], value: Bool) throws
    func setLsdDisabled(hashes: [String], value: Bool) throws
    func queueIncrease(hashes: [String]) throws
    func queueDecrease(hashes: [String]) throws
    func queueTop(hashes: [String]) throws
    func queueBottom(hashes: [String]) throws

    // MARK: Trackers, peers, web seeds
    func addTrackers(hash: String, trackers: [TrackerTierEntry]) throws
    func editTracker(hash: String, origUrl: String, newUrl: String) throws
    func removeTrackers(hash: String, urls: [String]) throws
    func replaceTrackers(hash: String, trackers: [TrackerTierEntry]) throws
    func addPeers(hashes: [String], peers: [String]) throws
    func banPeers(peers: [String]) throws
    func addWebSeeds(hash: String, urls: [String]) throws
    func editWebSeed(hash: String, origUrl: String, newUrl: String) throws
    func removeWebSeeds(hash: String, urls: [String]) throws

    // MARK: Categories and tags
    func categories() -> [Category]
    func createCategory(category: Category) throws
    func editCategory(category: Category) throws
    func removeCategories(names: [String]) throws
    func setCategory(hashes: [String], category: String) throws
    func tags() -> [String]
    func createTags(tags: [String]) throws
    func deleteTags(tags: [String]) throws
    func addTags(hashes: [String], tags: [String]) throws
    func removeTags(hashes: [String], tags: [String]) throws

    // MARK: Global transfer state
    func serverState() -> ServerState
    func altSpeedLimitsEnabled() -> Bool
    func setAltSpeedLimitsEnabled(enabled: Bool)
    func globalDownloadLimit() -> Int64
    func setGlobalDownloadLimit(limit: Int64) throws
    func globalUploadLimit() -> Int64
    func setGlobalUploadLimit(limit: Int64) throws
    func speedHistory(seconds: UInt32) -> [SpeedSample]

    // MARK: Log
    func mainLog(lastKnownId: Int64, levels: [LogLevel]) -> [LogMessage]
    func peerLog(lastKnownId: Int64) -> [PeerLogEntry]
    func clearLog()
}
