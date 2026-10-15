import Foundation

/// Tooltips of the rule definition fields.
enum RuleHelp {
    static func filter(regex: Bool, mustContain: Bool) -> String {
        let mode = regex
            ? String(localized: """
                Regex mode: use regular expressions (Perl-compatible syntax, as in qBittorrent). \
                Matching is case-insensitive.
                """)
            : String(localized: """
                Wildcard mode: you can use
                • ? to match any single character
                • * to match zero or more of any characters
                • Whitespaces count as AND operators (all words, any order)
                • | is used as OR operator
                If word order is important use * instead of whitespace.
                """)
        let empty = mustContain
            ? String(localized: "An expression with an empty | clause (e.g. expr|) will match all articles.")
            : String(localized: "An expression with an empty | clause (e.g. expr|) will exclude all articles.")
        return mode + "\n\n" + empty
    }

    static let episodeFilter = String(localized: """
        Matches articles based on episode filter.
        Example: 1x2;8-15;5;30-; will match 2, 5, 8 through 15, 30 and onward episodes of season one
        Episode filter rules:
        • Season number is a mandatory non-zero value
        • Episode number is a mandatory positive value
        • Filter must end with semicolon
        • Three range types for episodes are supported:
          ◦ Single number: 1x25; matches episode 25 of season one
          ◦ Normal range: 1x25-40; matches episodes 25 through 40 of season one
          ◦ Infinite range: 1x25-; matches episodes 25 and upward of season one, and all episodes of later seasons
        """)

    static let smartFilter = String(localized: """
        Smart Episode Filter will check the episode number to prevent downloading of duplicates.
        Supports the formats: S01E01, 1x1, 2017.12.31 and 31.12.2017 (Date formats also support - as a separator)
        """)

    /// "Last Match: %1 days ago" / "Last Match: Unknown" from an RFC 2822 date.
    static func lastMatch(_ text: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["EEE, dd MMM yyyy HH:mm:ss Z", "dd MMM yyyy HH:mm:ss Z", "EEE, d MMM yyyy HH:mm:ss Z"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) {
                let days = Calendar.current.dateComponents([.day], from: date, to: .now).day ?? 0
                return String(localized: "Last Match: \(max(days, 0)) days ago")
            }
        }
        return String(localized: "Last Match: Unknown")
    }
}
