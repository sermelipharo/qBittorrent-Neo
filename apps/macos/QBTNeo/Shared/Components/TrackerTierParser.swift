import Foundation

/// qBittorrent's `parseTrackerEntries`: one URL per line, blank lines start
/// a new tier; and the inverse used to prefill the editor.
enum TrackerTierParser {
    static func parse(_ text: String, baseTier: Int64 = 0) -> [TrackerTierEntry] {
        var tier = baseTier
        var result: [TrackerTierEntry] = []
        var seen = Set<String>()
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let url = line.trimmingCharacters(in: .whitespaces)
            if url.isEmpty {
                tier = tier == .max ? tier : tier + 1
                continue
            }
            if seen.insert(url).inserted { result.append(TrackerTierEntry(url: url, tier: tier)) }
        }
        return result
    }

    /// Text with tiers separated by blank lines (empty tiers add extra blank lines).
    static func format(_ entries: [TrackerTierEntry]) -> String {
        guard let maxTier = entries.map(\.tier).max() else { return "" }
        var lines: [String] = []
        for tier in 0...max(maxTier, 0) {
            if tier > 0 { lines.append("") }
            lines.append(contentsOf: entries.filter { $0.tier == tier }.map(\.url))
        }
        return lines.joined(separator: "\n")
    }
}
