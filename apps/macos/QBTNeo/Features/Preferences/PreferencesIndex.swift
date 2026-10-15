import Foundation

/// Static, localized index of every Settings label and section header, built once
/// (the entries live in `PreferencesIndex+Entries.swift`). Search folds case and
/// diacritics, so it works the same in every language.
enum PreferencesIndex {
    struct Entry: Sendable {
        let page: PreferencesPage
        /// Matches `.settingAnchor(_:)` on the view that shows the setting.
        let anchor: String
        let title: String
        let isSection: Bool

        init(_ page: PreferencesPage, _ anchor: String, _ title: String, section: Bool = false) {
            self.page = page
            self.anchor = anchor
            self.title = title
            self.isSection = section
        }
    }

    struct Result: Identifiable {
        let page: PreferencesPage
        /// Names of the matching settings inside the page (empty when only the page title matched).
        let matches: [String]
        /// Anchor of the best matching setting, if any.
        let anchor: String?
        var id: PreferencesPage { page }
    }

    /// Entry titles without their trailing colon, folded once for matching.
    private static let folded: [String] = all.map { fold(displayTitle($0.title)) }
    private static let foldedPageTitles: [PreferencesPage: String] = Dictionary(
        uniqueKeysWithValues: PreferencesPage.allCases.map { ($0, fold($0.title)) }
    )

    static func displayTitle(_ title: String) -> String {
        title.trimmingCharacters(in: CharacterSet(charactersIn: ":： ").union(.whitespaces))
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
    }

    /// Pages matching `query` (every word must be found in the page title or in a setting label), in page order.
    static func search(_ query: String) -> [Result] {
        let words = fold(query).split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        var matchesByPage: [PreferencesPage: [Int]] = [:]
        for (index, entry) in all.enumerated() {
            let text = folded[index]
            if words.allSatisfy({ text.contains($0) }) { matchesByPage[entry.page, default: []].append(index) }
        }
        return PreferencesPage.allCases.compactMap { page in
            let indices = matchesByPage[page] ?? []
            let titleMatches = words.allSatisfy { (foldedPageTitles[page] ?? "").contains($0) }
            guard titleMatches || !indices.isEmpty else { return nil }
            let first = indices.first { !all[$0].isSection } ?? indices.first
            return Result(
                page: page,
                matches: indices.map { displayTitle(all[$0].title) },
                anchor: first.map { all[$0].anchor }
            )
        }
    }
}
