import Foundation

/// Which article links may be opened or downloaded (features.md §5.9.4):
/// torrents only from http(s), magnet links or info hashes; news links
/// only http(s).
enum RSSLinkPolicy {
    static func isSupportedTorrentURL(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") || lower.hasPrefix("magnet:") { return true }
        let isHex = text.allSatisfy(\.isHexDigit)
        return isHex && (text.count == 40 || text.count == 64)
    }

    static func isWebURL(_ url: URL) -> Bool {
        let scheme = url.scheme?.lowercased()
        return scheme == "http" || scheme == "https"
    }

    /// Appends "There are %1 more articles with the same issue." when needed.
    static func summary(_ text: String, extra: Int) -> String {
        guard extra > 0 else { return text }
        return text + "\n" + String(localized: "There are \(extra) more articles with the same issue.")
    }
}
