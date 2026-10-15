import Foundation

/// Fuzzy matching for the Command Palette. Every word of the query must match
/// the title (or, for half the score, a keyword) as, best first:
/// a prefix, a substring at a word start, any substring, the starts of
/// consecutive words ("fr" → "Force Recheck"), or a subsequence that begins
/// at a word start. Case, diacritics and width are ignored (`FoldedText`).
struct FuzzyMatcher: Sendable {
    private let words: [[Unicode.Scalar]]

    /// Nil for an empty (or whitespace-only) query.
    init?(_ query: String) {
        let words = FoldedText.fold(query).split(whereSeparator: \.isWhitespace).map { Array($0.unicodeScalars) }
        guard !words.isEmpty else { return nil }
        self.words = words
    }

    /// Higher is better; nil when some query word matches neither the title nor a keyword.
    func score(title: FoldedText, keywords: [FoldedText] = []) -> Int? {
        var total = 0
        for word in words {
            var best = Self.score(word, in: title)
            for keyword in keywords {
                if let value = Self.score(word, in: keyword).map({ $0 / 2 }), value > (best ?? .min) { best = value }
            }
            guard let best else { return nil }
            total += best
        }
        // Shorter titles first among equal matches.
        return total - min(title.scalars.count, 120) / 8
    }

    // MARK: One word

    static func score(_ query: [Unicode.Scalar], in text: FoldedText) -> Int? {
        guard !query.isEmpty, query.count <= text.scalars.count else { return nil }
        if let position = substringPosition(query, in: text) {
            if position == 0 { return 1_000 }
            let penalty = min(position, 100)
            return text.isWordStart[position] ? 800 - penalty : 600 - penalty
        }
        if let starts = wordStartMatch(query, in: text) { return 400 + 10 * starts }
        if let gaps = subsequenceGaps(query, in: text) { return max(200 - gaps, 50) }
        return nil
    }

    /// First position of `query` in `text`, preferring one at a word start.
    private static func substringPosition(_ query: [Unicode.Scalar], in text: FoldedText) -> Int? {
        let scalars = text.scalars
        var first: Int?
        var start = 0
        while start + query.count <= scalars.count {
            if scalars[start] == query[0], scalars[start ..< start + query.count].elementsEqual(query) {
                if text.isWordStart[start] { return start }
                if first == nil { first = start }
            }
            start += 1
        }
        return first
    }

    /// Each query character continues the previous match or starts a word; returns the word starts used.
    private static func wordStartMatch(_ query: [Unicode.Scalar], in text: FoldedText) -> Int? {
        var index = 0
        var previous = -2
        var starts = 0
        for (position, scalar) in text.scalars.enumerated() where index < query.count && scalar == query[index] {
            let isStart = text.isWordStart[position]
            guard isStart || previous == position - 1 else { continue }
            if isStart { starts += 1 }
            previous = position
            index += 1
        }
        return index == query.count ? starts : nil
    }

    /// In-order match whose first character starts a word; returns the characters skipped in between.
    private static func subsequenceGaps(_ query: [Unicode.Scalar], in text: FoldedText) -> Int? {
        let scalars = text.scalars
        guard let first = scalars.indices.first(where: { scalars[$0] == query[0] && text.isWordStart[$0] }) else { return nil }
        var index = 1
        var gaps = 0
        var position = first + 1
        while index < query.count, position < scalars.count {
            if scalars[position] == query[index] {
                index += 1
            } else {
                gaps += 1
            }
            position += 1
        }
        return index == query.count ? gaps : nil
    }
}
