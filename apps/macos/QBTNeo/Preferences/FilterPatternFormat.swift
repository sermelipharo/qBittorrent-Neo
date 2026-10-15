import Foundation

/// Content filter pattern format (`FilterPatternFormat`): PlainText = 0,
/// Wildcards = 1 (default), Regex = 2.
enum FilterPatternFormat: Int, CaseIterable, Identifiable, Sendable {
    case plainText = 0
    case wildcards = 1
    case regex = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .plainText: String(localized: "Plain text")
        case .wildcards: String(localized: "Wildcards")
        case .regex: String(localized: "Regular expression")
        }
    }

    /// Builds a case-insensitive matcher for `pattern`; nil = match everything.
    func matcher(for pattern: String) -> TextMatcher? {
        let trimmed = pattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        switch self {
        case .plainText:
            return TextMatcher(substring: trimmed)
        case .wildcards:
            return TextMatcher(regex: Self.wildcardToRegex(trimmed)) ?? TextMatcher(substring: trimmed)
        case .regex:
            return TextMatcher(regex: trimmed) ?? TextMatcher(substring: trimmed)
        }
    }

    /// Qt's unanchored, non-path wildcard conversion: `*` and `?` match any
    /// character (including `/`), `[...]` sets are kept, the rest is literal.
    static func wildcardToRegex(_ pattern: String) -> String {
        var result = ""
        var inSet = false
        for character in pattern {
            switch character {
            case "*" where !inSet:
                result += ".*"
            case "?" where !inSet:
                result += "."
            case "[":
                inSet = true
                result.append(character)
            case "]":
                inSet = false
                result.append(character)
            default:
                result += inSet ? String(character) : NSRegularExpression.escapedPattern(for: String(character))
            }
        }
        return result
    }
}
