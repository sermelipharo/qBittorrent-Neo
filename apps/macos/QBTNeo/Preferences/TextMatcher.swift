import Foundation

/// A compiled, case-insensitive text filter (plain substring or regex).
struct TextMatcher: @unchecked Sendable {
    private let substring: String?
    private let regex: NSRegularExpression?

    init(substring: String) {
        self.substring = substring
        self.regex = nil
    }

    init?(regex pattern: String) {
        guard let compiled = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        self.substring = nil
        self.regex = compiled
    }

    func matches(_ text: String) -> Bool {
        if let substring {
            return text.localizedStandardContains(substring)
        }
        guard let regex else { return true }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }
}
