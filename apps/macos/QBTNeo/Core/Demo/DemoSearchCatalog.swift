import Foundation

/// Sample search plugins and generated results for the demo session.
enum DemoSearchCatalog {
    static let plugins: [SearchPlugin] = [
        plugin("archiveorg", "Internet Archive", "1.6", "https://archive.org", true, ["movies", "music", "books", "software"]),
        plugin("academictorrents", "Academic Torrents", "1.3", "https://academictorrents.com", true, ["books", "software"]),
        plugin("linuxtracker", "LinuxTracker", "2.2", "https://linuxtracker.org", true, ["software"]),
        plugin("publicdomaintorrents", "Public Domain Torrents", "1.1", "http://www.publicdomaintorrents.info", false, ["movies"]),
        plugin("etree", "etree.org", "0.9", "https://bt.etree.org", false, ["music"]),
    ]

    private static let categoryNames = [
        "anime": "Anime", "books": "Books", "games": "Games", "movies": "Movies", "music": "Music",
        "pictures": "Pictures", "software": "Software", "tv": "TV shows",
    ]

    private static func plugin(
        _ name: String, _ fullName: String, _ version: String, _ url: String, _ enabled: Bool, _ categories: [String]
    ) -> SearchPlugin {
        SearchPlugin(
            name: name, fullName: fullName, version: version, url: url, enabled: enabled,
            supportedCategories: categories.map { SearchCategory(id: $0, name: categoryNames[$0] ?? $0) }, iconPath: ""
        )
    }

    private static let suffixes = [
        "1080p WEB-DL", "Complete Collection", "2160p HDR", "FLAC 24bit-96kHz", "Original Broadcast", "x86_64 DVD ISO",
        "Live ISO", "Dataset v2", "EPUB + PDF", "Source Code", "Original Soundtrack", "Documentary 720p", "Remastered",
        "Lecture Videos", "Audiobook MP3 64kbps", "arm64 netinst",
    ]

    /// Up to ~36 results for `pattern` from the selected plugins; "zzz" gives none.
    static func results(pattern: String, plugins selected: [SearchPlugin]) -> [SearchResult] {
        let trimmed = pattern.trimmingCharacters(in: .whitespaces)
        guard !trimmed.lowercased().contains("zzz"), !selected.isEmpty else { return [] }
        var random = DemoRandom(trimmed.lowercased())
        let title = trimmed.split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: " ")
        let count = random.int(24...36)
        let now = Int64(Date.now.timeIntervalSince1970)
        return (0..<count).map { index in
            let engine = random.pick(selected)
            let year = random.int(1937...2025)
            let suffix = random.pick(suffixes)
            let name = random.unit() < 0.5 ? "\(title) (\(year)) \(suffix)" : "\(title).\(suffix.replacing(" ", with: "."))-\(index)"
            let size = Int64(pow(10, 7.5 + random.unit() * 3.4))
            let popularity = pow(random.unit(), 3)
            let slug = DemoRandom.hex(name, length: 12)
            let magnet = random.unit() < 0.6
            return SearchResult(
                fileName: name,
                fileUrl: magnet
                    ? "magnet:?xt=urn:btih:\(DemoRandom.hex(name, length: 40))&dn=\(name.replacing(" ", with: "+"))"
                    : "\(engine.url)/download/\(slug).torrent",
                fileSize: index % 11 == 7 ? -1 : size,
                seeders: Int64(popularity * 2_400), leechers: Int64(popularity * 380 + random.unit() * 6),
                engineName: engine.name, siteUrl: engine.url, descrLink: "\(engine.url)/details/\(slug)",
                pubDate: index % 9 == 4 ? -1 : now - Int64(random.int(3_600...(3 * 365 * 86_400)))
            )
        }
    }
}
