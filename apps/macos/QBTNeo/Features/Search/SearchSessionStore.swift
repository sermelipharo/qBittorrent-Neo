import Foundation

/// Persistence of the open search tabs (features.md §5.8.1, qBittorrent's
/// `SearchUI/Session.json` and per-tab result files) under
/// `<profile>/qBittorrent/data/SearchUI`. An actor, so writes happen off the main thread
/// and in order. Files are untrusted on load: tab IDs must be UUIDs (they
/// become file names), and file sizes and element counts are bounded.
actor SearchSessionStore {
    static let maxSessionBytes = 1 << 20
    static let maxResultsBytes = 128 << 20
    static let maxTabs = 200
    static let maxResultsPerTab = 200_000

    struct Session: Codable, Equatable {
        struct Tab: Codable, Equatable {
            var id: String
            var pattern: String

            enum CodingKeys: String, CodingKey {
                case id = "ID"
                case pattern = "SearchPattern"
            }
        }

        var tabs: [Tab]
        var currentTab: String

        enum CodingKeys: String, CodingKey {
            case tabs = "Tabs"
            case currentTab = "CurrentTab"
        }
    }

    /// One result in qBittorrent's file format.
    private struct StoredResult: Codable {
        var fileName: String
        var fileURL: String
        var fileSize: Int64
        var seeders: Int64
        var leechers: Int64
        var engineName: String
        var siteURL: String
        var descrLink: String
        var pubDate: Int64

        enum CodingKeys: String, CodingKey {
            case fileName = "FileName"
            case fileURL = "FileURL"
            case fileSize = "FileSize"
            case seeders = "SeedersCount"
            case leechers = "LeechersCount"
            case engineName = "EngineName"
            case siteURL = "SiteURL"
            case descrLink = "DescrLink"
            case pubDate = "PubDate"
        }

        init(_ result: SearchResult) {
            fileName = result.fileName
            fileURL = result.fileUrl
            fileSize = result.fileSize
            seeders = result.seeders
            leechers = result.leechers
            engineName = result.engineName
            siteURL = result.siteUrl
            descrLink = result.descrLink
            pubDate = result.pubDate
        }

        var result: SearchResult {
            SearchResult(
                fileName: fileName, fileUrl: fileURL, fileSize: fileSize, seeders: seeders, leechers: leechers,
                engineName: engineName, siteUrl: siteURL, descrLink: descrLink, pubDate: pubDate
            )
        }
    }

    private let directory: URL

    /// `profileRoot` is the profile folder (empty = the default one).
    init(profileRoot: String) {
        // The core's profile layout: `<root>/qBittorrent/data` (a qBittorrent custom profile).
        let root = profileRoot.isEmpty
            ? URL.applicationSupportDirectory.appending(path: "mk.lex.qbittorrentneo", directoryHint: .isDirectory)
            : URL(filePath: profileRoot, directoryHint: .isDirectory)
        directory = root.appending(path: "qBittorrent/data/SearchUI", directoryHint: .isDirectory)
    }

    private var sessionURL: URL { directory.appending(path: "Session.json", directoryHint: .notDirectory) }

    private func resultsURL(_ id: String) -> URL? {
        guard UUID(uuidString: id) != nil else { return nil }
        return directory.appending(path: "\(id).json", directoryHint: .notDirectory)
    }

    // MARK: Session

    func loadSession() -> Session? {
        guard let data = Self.read(sessionURL, limit: Self.maxSessionBytes),
              var session = try? JSONDecoder().decode(Session.self, from: data)
        else { return nil }
        var seen = Set<String>()
        session.tabs = session.tabs.prefix(Self.maxTabs).filter {
            UUID(uuidString: $0.id) != nil && seen.insert($0.id).inserted
        }
        return session
    }

    func saveSession(_ session: Session) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        write(data, to: sessionURL)
    }

    // MARK: Results

    func loadResults(id: String) -> [SearchResult] {
        guard let url = resultsURL(id), let data = Self.read(url, limit: Self.maxResultsBytes),
              let stored = try? JSONDecoder().decode([StoredResult].self, from: data)
        else { return [] }
        return stored.prefix(Self.maxResultsPerTab).map(\.result)
    }

    func saveResults(_ results: [SearchResult], id: String) {
        guard let url = resultsURL(id), let data = try? JSONEncoder().encode(results.map(StoredResult.init)) else { return }
        write(data, to: url)
    }

    func deleteResults(id: String) {
        if let url = resultsURL(id) { try? FileManager.default.removeItem(at: url) }
    }

    /// Removes every stored result file (and the session file when asked).
    func deleteAll(includingSession: Bool) {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "json" {
            if file.lastPathComponent == "Session.json" && !includingSession { continue }
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: Files

    private func write(_ data: Data, to url: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try? data.write(to: url, options: .atomic)
    }

    private static func read(_ url: URL, limit: Int) -> Data? {
        guard let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize, size <= limit else { return nil }
        return try? Data(contentsOf: url)
    }
}
