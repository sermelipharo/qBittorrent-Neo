import Foundation

/// `CoreClient` backed by qBittorrent's own C++ core running in-process
/// (see `CoreBridge` and docs/ARCHITECTURE.md). Argument names match the
/// handlers registered in core/src/api_*.cpp.
final class QtCoreClient: CoreClient {
    let bridge: CoreBridge

    /// Starts the core; blocks during start-up, so call it off the main actor.
    init(config: AppConfig) throws {
        bridge = try CoreBridge(config: config)
    }

    // MARK: Lifecycle and application

    func setEventListener(listener: any EventListener) {
        bridge.listener = listener
    }

    func shutdown() {
        bridge.shutdown()
    }

    func version() -> String {
        bridge.value("version", fallback: "")
    }

    func buildInfo() -> BuildInfo {
        bridge.value("buildInfo", fallback: .neoEmpty)
    }

    func preferences() -> Preferences {
        bridge.value("preferences", fallback: .qbtDefaults)
    }

    func setPreferences(prefs: Preferences) throws {
        try bridge.callVoid("setPreferences", ["prefs": prefs])
    }

    func defaultSavePath() -> String {
        bridge.value("defaultSavePath", fallback: "")
    }

    func freeDiskSpace(path: String) -> Int64 {
        bridge.value("freeDiskSpace", ["path": path], fallback: -1)
    }

    // MARK: Transfer list

    func syncMainData() -> MainDataUpdate {
        bridge.value("syncMainData", fallback: .neoEmpty)
    }

    func resetMainData() {
        try? bridge.callVoid("resetMainData")
    }

    // MARK: Properties tabs

    func properties(hash: String) throws -> TorrentProperties {
        try bridge.call("properties", ["hash": hash])
    }

    func trackers(hash: String) throws -> [TrackerEntry] {
        try bridge.call("trackers", ["hash": hash])
    }

    func webSeeds(hash: String) throws -> [WebSeed] {
        try bridge.call("webSeeds", ["hash": hash])
    }

    func files(hash: String, indexes: [Int64]) throws -> [TorrentFile] {
        try bridge.call("files", ["hash": hash, "indexes": indexes])
    }

    func pieceStates(hash: String) throws -> Data {
        try bridge.call("pieceStates", ["hash": hash])
    }

    func pieceAvailability(hash: String) throws -> [UInt32] {
        try bridge.call("pieceAvailability", ["hash": hash])
    }

    func peers(hash: String) throws -> [PeerInfo] {
        try bridge.call("peers", ["hash": hash])
    }

    func exportTorrent(hash: String) throws -> Data {
        try bridge.call("exportTorrent", ["hash": hash])
    }

    // MARK: Adding

    func addTorrent(source: TorrentSource, params: AddTorrentParams) async throws -> String {
        try await bridge.callAsync("addTorrent", ["source": source, "params": params])
    }

    func fetchMetadata(source: TorrentSource) async throws -> TorrentMetadataInfo {
        try await bridge.callAsync("fetchMetadata", ["source": source])
    }

    func saveFetchedMetadata(hash: String) throws -> Data {
        try bridge.call("saveFetchedMetadata", ["hash": hash])
    }

    // MARK: Global transfer state

    func serverState() -> ServerState {
        bridge.value("serverState", fallback: .neoEmpty)
    }

    func altSpeedLimitsEnabled() -> Bool {
        bridge.value("altSpeedLimitsEnabled", fallback: false)
    }

    func setAltSpeedLimitsEnabled(enabled: Bool) {
        try? bridge.callVoid("setAltSpeedLimitsEnabled", ["enabled": enabled])
    }

    func globalDownloadLimit() -> Int64 {
        bridge.value("globalDownloadLimit", fallback: 0)
    }

    func setGlobalDownloadLimit(limit: Int64) throws {
        try bridge.callVoid("setGlobalDownloadLimit", ["limit": limit])
    }

    func globalUploadLimit() -> Int64 {
        bridge.value("globalUploadLimit", fallback: 0)
    }

    func setGlobalUploadLimit(limit: Int64) throws {
        try bridge.callVoid("setGlobalUploadLimit", ["limit": limit])
    }

    func speedHistory(seconds: UInt32) -> [SpeedSample] {
        bridge.value("speedHistory", ["seconds": seconds], fallback: [])
    }

    // MARK: Log

    func mainLog(lastKnownId: Int64, levels: [LogLevel]) -> [LogMessage] {
        bridge.value("mainLog", ["lastKnownId": lastKnownId, "levels": levels], fallback: [])
    }

    func peerLog(lastKnownId: Int64) -> [PeerLogEntry] {
        bridge.value("peerLog", ["lastKnownId": lastKnownId], fallback: [])
    }

    func clearLog() {
        try? bridge.callVoid("clearLog")
    }
}
