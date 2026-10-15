import Foundation

/// Turns URLs inside plain text into links (qBittorrent's `parseHtmlLinks`),
/// for torrent comments. Comments are untrusted (they come from .torrent
/// files), so only web links become clickable: `file:`, `smb:` or custom
/// app schemes would hand attacker-chosen targets to LaunchServices.
enum LinkedText {
    static let linkSchemes: Set<String> = ["http", "https", "ftp"]

    static func attributed(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return result }
        let range = NSRange(text.startIndex..., in: text)
        for match in detector.matches(in: text, range: range) {
            guard let url = match.url,
                  let scheme = url.scheme?.lowercased(), linkSchemes.contains(scheme),
                  let textRange = Range(match.range, in: text),
                  let lower = AttributedString.Index(textRange.lowerBound, within: result),
                  let upper = AttributedString.Index(textRange.upperBound, within: result)
            else { continue }
            result[lower..<upper].link = url
        }
        return result
    }
}
