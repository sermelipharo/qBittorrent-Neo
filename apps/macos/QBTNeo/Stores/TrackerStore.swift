import Foundation
import Observation

/// Tracker URL → torrents map from `MainDataUpdate`, grouped by host for the
/// sidebar Trackers filter.
@Observable @MainActor
final class TrackerStore {
    /// Host → torrent IDs with at least one tracker on that host.
    private(set) var hostTorrents: [String: Set<String>] = [:]
    /// Hosts sorted naturally (case-sensitive, like qBittorrent).
    private(set) var sortedHosts: [String] = []
    @ObservationIgnored private var urlTorrents: [String: [String]] = [:]

    func apply(changed: [TrackerTorrents], removed: [String], fullUpdate: Bool) {
        guard fullUpdate || !changed.isEmpty || !removed.isEmpty else { return }
        if fullUpdate { urlTorrents.removeAll() }
        for url in removed { urlTorrents[url] = nil }
        for entry in changed { urlTorrents[entry.url] = entry.hashes }

        var hosts: [String: Set<String>] = [:]
        for (url, hashes) in urlTorrents where !hashes.isEmpty {
            hosts[Self.host(of: url), default: []].formUnion(hashes)
        }
        guard hosts != hostTorrents else { return }
        hostTorrents = hosts
        sortedHosts = hosts.keys.sorted { $0.compare($1, options: .numeric) == .orderedAscending }
    }

    /// URLs on `host` (for "Remove tracker" from all torrents).
    func urls(onHost host: String) -> [(url: String, hashes: [String])] {
        urlTorrents.filter { Self.host(of: $0.key) == host }.map { ($0.key, $0.value) }
    }

    /// `QUrl(url).host()`, or the raw URL when it cannot be parsed.
    nonisolated static func host(of url: String) -> String {
        URL(string: url)?.host(percentEncoded: false) ?? url
    }
}
