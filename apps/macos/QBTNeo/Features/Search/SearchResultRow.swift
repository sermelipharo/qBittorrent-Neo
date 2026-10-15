import Foundation

/// A search result with a stable identity and sortable columns.
struct SearchResultRow: Identifiable, Hashable {
    let id: Int
    let result: SearchResult

    var name: String { result.fileName }
    var size: Int64 { result.fileSize }
    var seeders: Int64 { result.seeders }
    var leechers: Int64 { result.leechers }
    var engine: String { result.engineName }
    var engineURL: String { result.siteUrl }
    var published: Int64 { result.pubDate }

    var sizeText: String { result.fileSize < 0 ? String(localized: "Unknown") : UnitFormatter.size(result.fileSize) }
    var publishedText: String { result.pubDate > 0 ? ValueFormatter.date(result.pubDate) : "" }
}
