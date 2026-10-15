import Foundation

/// Result name filter: the free-text filter (wildcards, or a regex) and the
/// "Torrent names only" rule — every word of the search pattern (or a quoted
/// phrase) must appear in the name.
struct SearchFilter {
    let text: String
    let regex: Bool
    let pattern: String
    let namesOnly: Bool

    func matches(_ name: String) -> Bool {
        if namesOnly, !matchesPattern(name) { return false }
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return true }
        let expression = regex ? trimmed : Self.wildcardRegex(trimmed)
        return name.range(of: expression, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func matchesPattern(_ name: String) -> Bool {
        let trimmed = pattern.trimmingCharacters(in: .whitespaces)
        if trimmed.count > 2, trimmed.hasPrefix("\""), trimmed.hasSuffix("\"") {
            return name.localizedStandardContains(String(trimmed.dropFirst().dropLast()))
        }
        return trimmed.split(separator: " ").allSatisfy { name.localizedStandardContains($0) }
    }

    /// `wildcardToRegularExpression`, unanchored.
    static func wildcardRegex(_ text: String) -> String {
        var result = ""
        for character in text {
            switch character {
            case "*": result += ".*"
            case "?": result += "."
            default: result += NSRegularExpression.escapedPattern(for: String(character))
            }
        }
        return result
    }
}
