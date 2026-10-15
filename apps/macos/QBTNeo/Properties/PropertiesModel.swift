import Foundation
import Observation

/// Data of the properties panel for the current torrent. Only the visible
/// tab is fetched, on the main refresh tick (qBittorrent's `loadDynamicData`).
@Observable @MainActor
final class PropertiesModel {
    private(set) var hash: String?

    // General
    private(set) var general: TorrentProperties?
    private(set) var pieces: [UInt8] = []
    private(set) var pieceAvailability: [UInt32] = []

    // Trackers
    private(set) var trackerRows: [TrackerRow] = []
    @ObservationIgnored private(set) var trackerEntries: [TrackerEntry] = []
    var expandedTrackers: Set<String> = [] { didSet { rebuildTrackerRows() } }
    var trackerSelection: Set<String> = []
    var trackerSortOrder: [KeyPathComparator<TrackerRow>] = [] { didSet { rebuildTrackerRows() } }

    // Peers
    private(set) var peers: [PeerRow] = []
    @ObservationIgnored private var rawPeers: [PeerRow] = []
    var peerSelection: Set<String> = []
    var peerSortOrder: [KeyPathComparator<PeerRow>] = [KeyPathComparator(\PeerRow.info.dlSpeed, order: .reverse)] {
        didSet { sortPeers() }
    }

    // HTTP sources
    private(set) var webSeeds: [WebSeedRow] = []
    var webSeedSelection: Set<String> = []

    // Content
    let files: FileTreeModel

    // Speed
    private(set) var speedPoints: [SpeedPoint] = []

    /// Tabs whose data the core could not provide (shown as unavailable).
    private(set) var failures: [PropertiesTab: String] = [:]

    init(patternFormat: FilterPatternFormat) {
        files = FileTreeModel(patternFormat: patternFormat)
    }

    /// Switches to another torrent, clearing per-torrent data.
    func show(hash: String?) {
        guard hash != self.hash else { return }
        self.hash = hash
        general = nil
        pieces = []
        pieceAvailability = []
        trackerEntries = []
        trackerRows = []
        trackerSelection = []
        expandedTrackers = []
        rawPeers = []
        peers = []
        peerSelection = []
        webSeeds = []
        webSeedSelection = []
        files.clear()
        failures = [:]
    }

    /// Fetches the data of `tab` for the current torrent.
    func refresh(tab: PropertiesTab, client: any CoreClient, item: TorrentItem?, period: SpeedGraphPeriod) async {
        if tab == .speed {
            let seconds = period.seconds
            let samples = await CoreCall.run { client.speedHistory(seconds: seconds) }
            let points = SpeedPoint.downsample(samples, resolution: period.resolution)
            if points != speedPoints { speedPoints = points }
            return
        }
        guard let hash else { return }
        do {
            switch tab {
            case .general:
                let wantsAvailability = item.map(Self.showsAvailability) ?? false
                let result = try await CoreCall.run { () throws -> (TorrentProperties, Data, [UInt32]) in
                    let properties = try client.properties(hash: hash)
                    let pieces = (try? client.pieceStates(hash: hash)) ?? Data()
                    let availability = wantsAvailability ? ((try? client.pieceAvailability(hash: hash)) ?? []) : []
                    return (properties, pieces, availability)
                }
                guard hash == self.hash else { return }
                if general != result.0 { general = result.0 }
                let newPieces = [UInt8](result.1)
                if newPieces != pieces { pieces = newPieces }
                if result.2 != pieceAvailability { pieceAvailability = result.2 }
            case .trackers:
                let entries = try await CoreCall.run { try client.trackers(hash: hash) }
                guard hash == self.hash else { return }
                if entries != trackerEntries {
                    trackerEntries = entries
                    rebuildTrackerRows()
                }
            case .peers:
                let list = try await CoreCall.run { try client.peers(hash: hash) }
                guard hash == self.hash else { return }
                rawPeers = list.map(PeerRow.init)
                sortPeers()
            case .httpSources:
                let seeds = try await CoreCall.run { try client.webSeeds(hash: hash) }
                guard hash == self.hash else { return }
                let rows = seeds.map { WebSeedRow(url: $0.url) }
                if rows != webSeeds { webSeeds = rows }
            case .content:
                let list = try await CoreCall.run { try client.files(hash: hash, indexes: []) }
                guard hash == self.hash else { return }
                files.load(list.map(FileEntry.init))
            case .speed:
                break
            }
            if failures[tab] != nil { failures[tab] = nil }
        } catch {
            guard hash == self.hash else { return }
            failures[tab] = error.userMessage
        }
    }

    /// The availability bar is shown only for torrents with metadata that are
    /// not finished, stopped, queued or checking.
    static func showsAvailability(_ item: TorrentItem) -> Bool {
        item.hasMetadata && !item.isFinished && !item.state.isStopped && !item.state.isQueued && !item.state.isChecking
    }

    func toggleTrackerExpansion(_ url: String) {
        if expandedTrackers.contains(url) {
            expandedTrackers.remove(url)
        } else {
            expandedTrackers.insert(url)
        }
    }

    private func rebuildTrackerRows() {
        var sticky: [TrackerRow] = []
        var real: [TrackerEntry] = []
        for entry in trackerEntries {
            if entry.tier < 0 { sticky.append(TrackerRow(entry: entry)) } else { real.append(entry) }
        }
        var trackerRows = real.map(TrackerRow.init(entry:))
        if !trackerSortOrder.isEmpty { trackerRows.sort(using: trackerSortOrder) }
        var rows = sticky
        for row in trackerRows {
            rows.append(row)
            if expandedTrackers.contains(row.url), let entry = real.first(where: { $0.url == row.url }) {
                rows.append(contentsOf: entry.endpoints.map { TrackerRow(endpoint: $0, parent: entry) })
            }
        }
        if rows != self.trackerRows { self.trackerRows = rows }
    }

    private func sortPeers() {
        var sorted = rawPeers
        if !peerSortOrder.isEmpty { sorted.sort(using: peerSortOrder) }
        if sorted != peers { peers = sorted }
        if !peerSelection.isEmpty {
            let ids = Set(sorted.map(\.id))
            let kept = peerSelection.intersection(ids)
            if kept != peerSelection { peerSelection = kept }
        }
    }
}
