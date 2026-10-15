import Foundation
import Observation

/// Global session state (`ServerState`) split into separately observed
/// properties, so the status bar's speed labels update every tick without
/// invalidating views that only read, say, the queueing flag.
@Observable @MainActor
final class SessionStatus {
    var downloadRate: Int64 = 0
    var uploadRate: Int64 = 0
    var downloadSession: Int64 = 0
    var uploadSession: Int64 = 0
    var downloadLimit: Int64 = 0
    var uploadLimit: Int64 = 0
    var dhtNodes: Int64 = 0
    var connectionStatus: ConnectionStatus = .disconnected
    var queueingEnabled = false
    var altSpeedEnabled = false
    /// Torrents transferring data now / all torrents (kept current only while the menu bar item shows counts).
    var activeTorrents = 0
    var totalTorrents = 0
    var freeSpace: Int64 = -1
    var externalIPv4 = ""
    var externalIPv6 = ""
    var allTimeDownload: Int64 = 0
    var allTimeUpload: Int64 = 0
    var globalRatio = 0.0
    var peerConnections: Int64 = 0
    /// The full record, for windows that show many fields (Statistics).
    @ObservationIgnored private(set) var serverState = ServerState.blank

    func apply(_ state: ServerState) {
        guard state != serverState else { return }
        serverState = state
        downloadRate = state.dlSpeed
        uploadRate = state.upSpeed
        downloadSession = state.dlSessionData
        uploadSession = state.upSessionData
        downloadLimit = state.dlRateLimit
        uploadLimit = state.upRateLimit
        dhtNodes = state.dhtNodes
        connectionStatus = state.connectionStatus
        queueingEnabled = state.queueing
        altSpeedEnabled = state.useAltSpeedLimits
        freeSpace = state.freeSpaceOnDisk
        externalIPv4 = state.lastExternalAddressV4
        externalIPv6 = state.lastExternalAddressV6
        allTimeDownload = state.alltimeDownload
        allTimeUpload = state.alltimeUpload
        globalRatio = state.globalRatio
        peerConnections = state.totalPeerConnections
    }

    func applyCounts(active: Int, total: Int) {
        if activeTorrents != active { activeTorrents = active }
        if totalTorrents != total { totalTorrents = total }
    }

    /// Whether any torrent is transferring payload (exit confirmation rule).
    var isTransferring: Bool { downloadRate > 0 || uploadRate > 0 }
}
