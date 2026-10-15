import Foundation

/// A simplified version of the core's RSS rule matching (must contain / must
/// not contain / episode filter) for the demo session's preview.
struct DemoRuleMatcher {
    let rule: RssAutoDownloadRule

    func matches(_ title: String) -> Bool {
        if !rule.mustContain.isEmpty, !anyAlternative(rule.mustContain, matches: title) { return false }
        if !rule.mustNotContain.isEmpty, anyAlternative(rule.mustNotContain, matches: title) { return false }
        if !rule.episodeFilter.isEmpty, !episodeMatches(title) { return false }
        return true
    }

    private func anyAlternative(_ expression: String, matches title: String) -> Bool {
        if rule.useRegex {
            guard let regex = try? NSRegularExpression(pattern: expression, options: .caseInsensitive) else { return false }
            return regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil
        }
        return expression.split(separator: "|", omittingEmptySubsequences: false).contains { alternative in
            let tokens = alternative.split(whereSeparator: \.isWhitespace)
            return tokens.allSatisfy { Self.wildcard(String($0), matches: title) }
        }
    }

    static func wildcard(_ token: String, matches text: String) -> Bool {
        var pattern = ""
        for character in token {
            switch character {
            case "*": pattern += ".*"
            case "?": pattern += "."
            default: pattern += NSRegularExpression.escapedPattern(for: String(character))
            }
        }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return false }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    /// `1x2;8-15;5;30-;`: season 1, episodes 2, 5, 8…15 and 30 onwards.
    private func episodeMatches(_ title: String) -> Bool {
        guard let (season, episode) = Self.episode(in: title) else { return false }
        let parts = rule.episodeFilter.lowercased().split(separator: "x", maxSplits: 1)
        guard parts.count == 2, let filterSeason = Int(parts[0]), filterSeason > 0 else { return false }
        if season < filterSeason { return false }
        for range in parts[1].split(separator: ";") {
            let bounds = range.split(separator: "-", omittingEmptySubsequences: false)
            guard let low = Int(bounds[0]) else { continue }
            if bounds.count == 1, season == filterSeason, episode == low { return true }
            if bounds.count == 2 {
                if bounds[1].isEmpty {
                    if season > filterSeason || episode >= low { return true }
                } else if let high = Int(bounds[1]), season == filterSeason, (low...max(low, high)).contains(episode) {
                    return true
                }
            }
        }
        return false
    }

    static func episode(in title: String) -> (season: Int, episode: Int)? {
        let patterns = [#"s0?(\d{1,4})[ -_\.]?e(0?\d{1,4})"#, #"\b(\d{1,4})x(0?\d{1,4})"#]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
                  let seasonRange = Range(match.range(at: 1), in: title),
                  let episodeRange = Range(match.range(at: 2), in: title),
                  let season = Int(title[seasonRange]), let episode = Int(title[episodeRange])
            else { continue }
            return (season, episode)
        }
        return nil
    }
}
