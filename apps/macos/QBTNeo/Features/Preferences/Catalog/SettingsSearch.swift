import Foundation

/// Settings search over the catalog: every word of the query must appear in
/// the label, the section or pane title, a keyword, or a stored key (WebAPI
/// or ini name). Case, diacritics and width are ignored, so it works the same
/// in every language. Covers all tiers.
@MainActor
enum SettingsSearch {
    struct Result: Identifiable {
        let spec: SettingSpec
        var id: String { spec.id }
        /// "Pane › Section".
        var path: String { "\(spec.pane.title) › \(spec.section.title)" }
        var title: String { displayTitle(spec.title) }
    }

    static let limit = 40

    /// One catalog entry's searchable text, folded once, by relevance.
    private struct Entry {
        let spec: SettingSpec
        /// Label; section and pane titles; keywords and stored keys; explanation.
        let fields: [String]
        let all: String
    }

    private static let entries: [Entry] = SettingsCatalog.all.filter(\.tier.hasRow).map { spec in
        let fields = [
            spec.title,
            spec.section.title + " " + spec.pane.title,
            (spec.keywords + spec.keys).joined(separator: " \u{1F} "),
            spec.help ?? "",
        ].map { fold($0) }
        return Entry(spec: spec, fields: fields, all: fields.joined(separator: " \u{1F} "))
    }

    /// Matches ranked by where the words were found (label, section, keyword,
    /// explanation), then in catalog (pane) order.
    static func search(_ query: String) -> [Result] {
        let words = fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        let ranked = entries.compactMap { entry -> (rank: Int, spec: SettingSpec)? in
            guard words.allSatisfy({ entry.all.contains($0) }) else { return nil }
            let rank = entry.fields.firstIndex { field in words.allSatisfy { field.contains($0) } } ?? entry.fields.count
            return (rank, entry.spec)
        }
        let ordered = ranked.enumerated().sorted { ($0.element.rank, $0.offset) < ($1.element.rank, $1.offset) }
        return ordered.prefix(limit).map { Result(spec: $0.element.spec) }
    }

    /// The label without its trailing colon.
    nonisolated static func displayTitle(_ title: String) -> String {
        title.trimmingCharacters(in: CharacterSet(charactersIn: ":：").union(.whitespaces))
    }

    nonisolated private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
    }
}
