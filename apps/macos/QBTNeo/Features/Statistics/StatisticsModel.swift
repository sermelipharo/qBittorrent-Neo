import Foundation
import Observation

/// Statistics window data (features.md §3.14): the full `ServerState`,
/// polled at the session refresh interval while the window is open.
@Observable @MainActor
final class StatisticsModel {
    private(set) var state = ServerState.blank

    /// Polls until the calling task is cancelled (window closed).
    func run(app: AppModel) async {
        while !Task.isCancelled {
            if let client = app.client {
                state = await CoreCall.run { client.serverState() }
            }
            let interval = max(app.corePreferences.advanced.refreshInterval, 500)
            try? await Task.sleep(for: .milliseconds(interval))
        }
    }

    // MARK: Formatted values

    var allTimeUpload: String { UnitFormatter.size(state.alltimeUpload) }
    var allTimeDownload: String { UnitFormatter.size(state.alltimeDownload) }

    /// `allTimeUL / allTimeDL` with two decimals, "-" when either is zero.
    var allTimeShareRatio: String {
        guard state.alltimeUpload > 0, state.alltimeDownload > 0 else { return "-" }
        let ratio = Double(state.alltimeUpload) / Double(state.alltimeDownload)
        return ratio.formatted(.number.precision(.fractionLength(2)))
    }

    var sessionWaste: String { UnitFormatter.size(state.totalWastedSession) }
    var connectedPeers: String { state.totalPeerConnections.formatted() }
    var totalBufferSize: String { UnitFormatter.size(state.totalBuffersSize) }
    var writeCacheOverload: String { Self.percent(state.writeCacheOverload) }
    var readCacheOverload: String { Self.percent(state.readCacheOverload) }
    var queuedIOJobs: String { state.queuedIoJobs.formatted() }
    var averageTimeInQueue: String { String(localized: "\(state.averageTimeQueue.formatted()) ms") }
    var totalQueuedSize: String { UnitFormatter.size(state.totalQueuedSize) }

    private static func percent(_ value: Double) -> String {
        guard value > 0 else { return "0%" }
        return "\(value.formatted(.number.precision(.fractionLength(2))))%"
    }
}
