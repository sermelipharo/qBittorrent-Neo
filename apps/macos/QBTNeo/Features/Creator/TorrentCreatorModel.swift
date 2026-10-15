import AppKit
import Observation

/// Torrent Creator state (features.md §3.5): inputs persisted under
/// `TorrentCreator/*`, piece counting, and the creation task polled from
/// the core with cancel.
@Observable @MainActor
final class TorrentCreatorModel {
    static let pieceSizes: [Int64] = [0] + (4...17).map { Int64(1_024) << $0 }
    static let formats: [TorrentFormat] = [.v2, .hybrid, .v1]

    var sourcePath: String { didSet { if sourcePath != oldValue { progress = 0; pieceCount = nil; save() } } }
    var format: TorrentFormat { didSet { pieceCount = nil; save() } }
    var pieceSize: Int64 { didSet { pieceCount = nil; save() } }
    var isPrivate: Bool { didSet { save() } }
    var startSeeding: Bool { didSet { save() } }
    var ignoreShareLimits: Bool { didSet { save() } }
    var optimizeAlignment: Bool { didSet { save() } }
    var paddingLimitKiB: Int64 { didSet { save() } }
    var trackers: String { didSet { save() } }
    var webSeeds: String { didSet { save() } }
    var comment: String { didSet { save() } }
    var source: String { didSet { save() } }

    private(set) var pieceCount: Int64?
    private(set) var isCounting = false
    private(set) var progress = 0.0
    private(set) var isCreating = false
    var alert: RSSAlert?

    @ObservationIgnored private var client: (any CreatorClient)?
    @ObservationIgnored private var taskID: String?
    @ObservationIgnored private let defaults = AppDefaults.store

    init() {
        let read = AppDefaults.store
        sourcePath = read.string(forKey: FeatureDefaults.creatorLastAddPath) ?? NSHomeDirectory()
        let formatIndex = read.object(forKey: FeatureDefaults.creatorFormat) as? Int ?? 1
        format = Self.formats.indices.contains(formatIndex) ? Self.formats[formatIndex] : .hybrid
        let stored = Int64(read.integer(forKey: FeatureDefaults.creatorPieceSize))
        pieceSize = Self.pieceSizes.contains(stored) ? stored : 0
        isPrivate = read.bool(forKey: FeatureDefaults.creatorPrivate)
        startSeeding = read.bool(forKey: FeatureDefaults.creatorStartSeeding)
        ignoreShareLimits = read.bool(forKey: FeatureDefaults.creatorIgnoreRatio)
        optimizeAlignment = read.object(forKey: FeatureDefaults.creatorOptimizeAlignment) as? Bool ?? true
        paddingLimitKiB = read.object(forKey: FeatureDefaults.creatorPaddingLimit) as? Int64 ?? -1
        trackers = read.string(forKey: FeatureDefaults.creatorTrackers) ?? ""
        webSeeds = read.string(forKey: FeatureDefaults.creatorWebSeeds) ?? ""
        comment = read.string(forKey: FeatureDefaults.creatorComments) ?? ""
        source = read.string(forKey: FeatureDefaults.creatorSource) ?? ""
    }

    func attach(_ client: (any CoreClient)?) {
        self.client = client as? any CreatorClient
    }

    private func save() {
        defaults.set(sourcePath, forKey: FeatureDefaults.creatorLastAddPath)
        defaults.set(Self.formats.firstIndex(of: format) ?? 1, forKey: FeatureDefaults.creatorFormat)
        defaults.set(pieceSize, forKey: FeatureDefaults.creatorPieceSize)
        defaults.set(isPrivate, forKey: FeatureDefaults.creatorPrivate)
        defaults.set(startSeeding, forKey: FeatureDefaults.creatorStartSeeding)
        defaults.set(ignoreShareLimits, forKey: FeatureDefaults.creatorIgnoreRatio)
        defaults.set(optimizeAlignment, forKey: FeatureDefaults.creatorOptimizeAlignment)
        defaults.set(paddingLimitKiB, forKey: FeatureDefaults.creatorPaddingLimit)
        defaults.set(trackers, forKey: FeatureDefaults.creatorTrackers)
        defaults.set(webSeeds, forKey: FeatureDefaults.creatorWebSeeds)
        defaults.set(comment, forKey: FeatureDefaults.creatorComments)
        defaults.set(source, forKey: FeatureDefaults.creatorSource)
    }

    static func pieceSizeTitle(_ size: Int64) -> String {
        if size == 0 { return String(localized: "Auto") }
        return size < 1 << 20 ? "\(size >> 10)\u{00A0}\(UnitFormatter.kib)" : "\(size >> 20)\u{00A0}\(UnitFormatter.mib)"
    }

    // MARK: Pieces

    func calculatePieces() async {
        guard let client else { return }
        isCounting = true
        defer { isCounting = false }
        let (path, size, format) = (sourcePath, pieceSize, format)
        do {
            pieceCount = try await client.creatorCalculatePieces(sourcePath: path, pieceSize: size, format: format)
        } catch {
            alert = RSSAlert(title: String(localized: "Torrent creation failed"), message: error.userMessage)
        }
    }

    // MARK: Creating

    /// Tracker text: blank lines separate tiers; runs of blank lines collapse.
    var trackerList: [String] {
        var result: [String] = []
        for line in trackers.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if let last = result.last, !last.isEmpty { result.append("") }
            } else {
                result.append(trimmed)
            }
        }
        while result.last == "" { result.removeLast() }
        return result
    }

    var defaultTorrentName: String {
        URL(filePath: sourcePath).lastPathComponent + ".torrent"
    }

    func create(savingTo url: URL) {
        guard let client else { return }
        guard FileManager.default.isReadableFile(atPath: sourcePath) else {
            alert = RSSAlert(title: String(localized: "Torrent creation failed"),
                             message: String(localized: "Reason: Path to file/folder is not readable."))
            return
        }
        defaults.set(url.deletingLastPathComponent().path(percentEncoded: false), forKey: FeatureDefaults.creatorLastSavePath)
        let params = TorrentCreatorParams(
            sourcePath: sourcePath, torrentFilePath: url.path(percentEncoded: false), format: format, pieceSize: pieceSize,
            optimizeAlignment: optimizeAlignment, paddingFileLimit: paddingLimitKiB < 0 ? -1 : paddingLimitKiB * 1_024,
            private: isPrivate, startSeeding: startSeeding, ignoreShareLimits: startSeeding && ignoreShareLimits,
            trackers: trackerList, urlSeeds: PreferencesModel.lines(webSeeds),
            comment: comment, source: source.trimmingCharacters(in: .whitespaces)
        )
        do {
            let id = try client.creatorAddTask(params: params)
            taskID = id
            isCreating = true
            progress = 0
            Task { await poll(id, path: url.path(percentEncoded: false)) }
        } catch {
            alert = RSSAlert(title: String(localized: "Torrent creation failed"),
                             message: String(localized: "Create new torrent file failed. Reason: \(error.userMessage)."))
        }
    }

    private func poll(_ id: String, path: String) async {
        guard let client else { return }
        while isCreating, taskID == id {
            guard let task = try? await CoreCall.run({ try client.creatorTask(id: id) }) else { break }
            progress = task.progress / 100
            switch task.status {
            case .finished:
                finish(id, message: String(localized: "Torrent created:\n\(path)"), title: String(localized: "Torrent creator"))
                return
            case .failed:
                finish(id, message: String(localized: "Create new torrent file failed. Reason: \(task.errorMessage)."),
                       title: String(localized: "Torrent creation failed"))
                return
            default:
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    private func finish(_ id: String, message: String, title: String) {
        isCreating = false
        taskID = nil
        try? client?.creatorDeleteTask(id: id)
        alert = RSSAlert(title: title, message: message)
    }

    /// Cancel: the task is removed, which interrupts hashing.
    func cancel() {
        guard let id = taskID else { return }
        try? client?.creatorDeleteTask(id: id)
        taskID = nil
        isCreating = false
        progress = 0
    }
}
