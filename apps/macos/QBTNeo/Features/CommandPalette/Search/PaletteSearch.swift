import Foundation

/// Turns the index and the query into the palette's sections. Cheap per
/// keystroke: candidates are folded in advance, and only the best few rows
/// of each section are kept.
@MainActor
enum PaletteSearch {
    private struct Scored {
        let score: Int
        let order: Int
        let item: PaletteItem
    }

    /// Root list: recent rows and every available action for an empty query,
    /// otherwise matching actions, torrents, filters and settings, sections ordered by their best match.
    static func root(query: String, index: PaletteIndex, recents: PaletteRecents, app: AppModel) -> [PaletteResultSection] {
        guard let matcher = FuzzyMatcher(query) else {
            let recent = recents.ids.lazy.compactMap { resolve($0, index: index, app: app) }.prefix(PaletteSection.recent.limit)
            let recentIDs = Set(recent.map(\.id))
            let actions = index.commands.map(\.item).filter { !recentIDs.contains($0.id) }
            return [PaletteResultSection(section: .recent, items: Array(recent)), PaletteResultSection(section: .actions, items: actions)]
                .filter { !$0.items.isEmpty }
        }
        var groups: [(section: PaletteSection, rows: [Scored])] = [
            (.actions, rank(index.commands, matcher, recents, limit: PaletteSection.actions.limit)),
            (.torrents, rank(index.torrents, matcher, recents, limit: PaletteSection.torrents.limit)),
            (.filters, rank(index.filters, matcher, recents, limit: PaletteSection.filters.limit)),
            (.settings, settings(query, matcher, recents)),
        ]
        groups = groups.filter { !$0.rows.isEmpty }
        let order: [PaletteSection] = [.actions, .torrents, .filters, .settings]
        groups.sort { lhs, rhs in
            let left = lhs.rows[0].score
            let right = rhs.rows[0].score
            if left != right { return left > right }
            return (order.firstIndex(of: lhs.section) ?? 0) < (order.firstIndex(of: rhs.section) ?? 0)
        }
        return groups.map { PaletteResultSection(section: $0.section, items: $0.rows.map(\.item)) }
    }

    /// A nested list (torrent actions, categories, tags) filtered by the query, in list order when it is empty.
    static func nested(_ candidates: [PaletteCandidate], section: PaletteSection, query: String,
                       recents: PaletteRecents) -> [PaletteResultSection] {
        let items: [PaletteItem]
        if let matcher = FuzzyMatcher(query) {
            items = rank(candidates, matcher, recents, limit: section.limit).map(\.item)
        } else {
            items = candidates.map(\.item)
        }
        return items.isEmpty ? [] : [PaletteResultSection(section: section, items: items)]
    }

    // MARK: Ranking

    private static func rank(_ candidates: [PaletteCandidate], _ matcher: FuzzyMatcher, _ recents: PaletteRecents,
                             limit: Int) -> [Scored] {
        var scored: [Scored] = []
        for (order, candidate) in candidates.enumerated() {
            guard let score = matcher.score(title: candidate.title, keywords: candidate.keywords) else { continue }
            scored.append(Scored(score: score + recents.boost(candidate.item.id), order: order, item: candidate.item))
        }
        // Partial selection of the best rows: no full sort of a large list.
        var best: [Scored] = []
        best.reserveCapacity(limit + 1)
        for entry in scored {
            guard best.count < limit || isBetter(entry, than: best[best.count - 1]) else { continue }
            let position = best.firstIndex { isBetter(entry, than: $0) } ?? best.count
            best.insert(entry, at: position)
            if best.count > limit { best.removeLast() }
        }
        return best
    }

    private static func isBetter(_ lhs: Scored, than rhs: Scored) -> Bool {
        lhs.score != rhs.score ? lhs.score > rhs.score : lhs.order < rhs.order
    }

    /// The Settings window's own search (same words, same ranking), scored for section ordering.
    private static func settings(_ query: String, _ matcher: FuzzyMatcher, _ recents: PaletteRecents) -> [Scored] {
        SettingsSearch.search(query).prefix(PaletteSection.settings.limit).enumerated().map { order, result in
            let item = PaletteIndex.setting(result)
            let score = (matcher.score(title: FoldedText(item.title)) ?? 150) + recents.boost(item.id)
            return Scored(score: score, order: order, item: item)
        }
        .sorted(by: isBetter)
    }

    // MARK: Recent rows

    private static func resolve(_ id: String, index: PaletteIndex, app: AppModel) -> PaletteItem? {
        if let item = index.byID[id] { return item }
        if id.hasPrefix("torrent:"), let torrent = app.transfers.item(String(id.dropFirst("torrent:".count))) {
            return PaletteIndex.torrentCandidate(torrent).item
        }
        if id.hasPrefix("setting:") {
            let key = id.dropFirst("setting:".count)
            if let spec = SettingsCatalog.all.first(where: { $0.id == key && $0.tier.hasRow }) {
                return PaletteIndex.setting(SettingsSearch.Result(spec: spec))
            }
        }
        return nil
    }
}
