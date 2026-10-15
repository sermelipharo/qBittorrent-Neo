import Foundation
import Observation

/// State of one "Add new torrent" dialog (features.md §3.1): options,
/// metadata retrieval (cancellable), content tree with priorities and renames.
@Observable @MainActor
final class AddTorrentModel {
    enum Phase: Equatable {
        case retrievingMetadata
        case ready
        case failed(String)
        case duplicate
    }

    let source: TorrentSource
    private(set) var phase: Phase = .retrievingMetadata
    private(set) var metadata: TorrentMetadataInfo?
    private(set) var title: String

    // MARK: Options
    var autoTMM: Bool { didSet { updateAutomaticPaths() } }
    var savePath: String { didSet { updateFreeSpace() } }
    var useDownloadPath: Bool
    var downloadPath: String
    var rememberLastSavePath: Bool
    var category: String { didSet { updateAutomaticPaths() } }
    var setAsDefaultCategory = false
    var tags: [String] = []
    var startTorrent: Bool
    var stopCondition: StopCondition
    var addToQueueTop: Bool
    var skipHashCheck = false
    var sequential = false
    var firstLastPiece = false
    var contentLayout: ContentLayout { didSet { if contentLayout != oldValue { rebuildTree() } } }
    var neverShowAgain = false

    let tree: FileTreeModel
    private(set) var freeSpace: Int64 = -1
    let savePathHistory: [String]
    let downloadPathHistory: [String]
    let categoryChoices: [String]

    @ObservationIgnored private let client: any CoreClient
    @ObservationIgnored private let preferences: Preferences
    @ObservationIgnored private let categories: [String: Category]
    @ObservationIgnored private var fetchTask: Task<Void, Never>?
    /// Base (original-layout) relative path per file index, with renames applied.
    @ObservationIgnored private var basePaths: [Int: String] = [:]
    @ObservationIgnored private var renamed = false
    @ObservationIgnored private var rootOverride: String?

    init(source: TorrentSource, client: any CoreClient, app: AppModel) {
        self.source = source
        self.client = client
        let prefs = app.corePreferences
        preferences = prefs
        categories = app.categories.categories
        title = Self.initialTitle(for: source)
        let gui = app.gui
        let defaultSave = prefs.downloads.savePath.isEmpty ? client.defaultSavePath() : prefs.downloads.savePath
        savePathHistory = gui.savePathHistory.isEmpty ? [defaultSave] : gui.savePathHistory
        downloadPathHistory = gui.downloadPathHistory
        rememberLastSavePath = gui.rememberLastSavePath
        savePath = gui.rememberLastSavePath ? (gui.savePathHistory.first ?? defaultSave) : defaultSave
        useDownloadPath = prefs.downloads.tempPathEnabled
        downloadPath = prefs.downloads.tempPath.isEmpty ? defaultSave + "/temp" : prefs.downloads.tempPath
        autoTMM = prefs.downloads.autoTmmEnabled
        startTorrent = !prefs.downloads.addStoppedEnabled
        stopCondition = prefs.downloads.torrentStopCondition
        addToQueueTop = prefs.downloads.addToTopOfQueue
        contentLayout = prefs.downloads.torrentContentLayout
        var choices: [String] = []
        if !gui.defaultCategory.isEmpty { choices.append(gui.defaultCategory) }
        choices.append("")
        for name in app.categories.sortedNames where !choices.contains(name) { choices.append(name) }
        categoryChoices = choices
        category = choices.first ?? ""
        tree = FileTreeModel(patternFormat: gui.addTorrentFilterPatternFormat)
        updateAutomaticPaths()
        updateFreeSpace()
    }

    // MARK: Metadata

    func beginFetch(onDuplicate: @escaping @MainActor (TorrentMetadataInfo) -> Void) {
        fetchTask = Task { [weak self, client, source] in
            do {
                let metadata = try await client.fetchMetadata(source: source)
                guard let self, !Task.isCancelled else { return }
                if metadata.isDuplicate {
                    self.phase = .duplicate
                    onDuplicate(metadata)
                    return
                }
                self.received(metadata)
            } catch is CancellationError {
                return
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.phase = .failed(error.userMessage)
            }
        }
    }

    /// Stops metadata retrieval (dialog closed or cancelled).
    func cancel() {
        fetchTask?.cancel()
        fetchTask = nil
    }

    /// Uses metadata that is already known (snapshots, previews).
    func received(_ metadata: TorrentMetadataInfo) {
        self.metadata = metadata
        title = metadata.name
        basePaths = Dictionary(uniqueKeysWithValues: metadata.files.map { (Int($0.index), $0.path) })
        // "Metadata received" no longer applies once metadata is present.
        if stopCondition == .metadataReceived {
            startTorrent = false
            stopCondition = .none
        }
        rebuildTree(applyExclusions: true)
        tree.expandAll()
        phase = .ready
    }

    var hasMetadata: Bool { metadata != nil }

    var canSaveTorrentFile: Bool { metadata != nil && (metadata?.infohashV2.isEmpty ?? true) }

    /// The fetched metadata as a .torrent file ("Save as .torrent file…").
    var torrentDocument: TorrentFileDocument? {
        guard let hash = metadata?.hash, let data = try? client.saveFetchedMetadata(hash: hash) else { return nil }
        return TorrentFileDocument(data: data)
    }

    // MARK: Content tree

    private var commonRoot: String? {
        let paths = basePaths.values
        guard let first = paths.first?.split(separator: "/").first, paths.allSatisfy({ $0.contains("/") }) else { return nil }
        let root = String(first)
        return paths.allSatisfy { $0.hasPrefix(root + "/") } ? root : nil
    }

    private var addedRootName: String {
        if let rootOverride { return rootOverride }
        let name = metadata?.name ?? title
        return basePaths.count == 1 ? (name as NSString).deletingPathExtension : name
    }

    /// Path shown in the tree for a base path, with the content layout applied.
    private func displayPath(_ base: String) -> String {
        switch contentLayout {
        case .original:
            return base
        case .subfolder:
            return commonRoot == nil ? addedRootName + "/" + base : base
        case .noSubfolder:
            guard let root = commonRoot else { return base }
            return String(base.dropFirst(root.count + 1))
        }
    }

    private func basePath(_ display: String) -> String {
        switch contentLayout {
        case .original:
            return display
        case .subfolder:
            guard commonRoot == nil else { return display }
            return display.split(separator: "/").dropFirst().joined(separator: "/")
        case .noSubfolder:
            guard let root = commonRoot else { return display }
            return root + "/" + display
        }
    }

    private func rebuildTree(applyExclusions: Bool = false) {
        guard let metadata else { return }
        let previous = Dictionary(uniqueKeysWithValues: metadata.files.compactMap { file -> (Int, FilePriority)? in
            guard let node = tree.node(forFileIndex: Int(file.index)), let priority = node.priority.filePriority else { return nil }
            return (Int(file.index), priority)
        })
        let excluded = applyExclusions ? exclusionMatchers() : []
        let entries = metadata.files.map { file in
            let index = Int(file.index)
            let base = basePaths[index] ?? file.path
            var priority = previous[index] ?? .normal
            let name = (base as NSString).lastPathComponent
            if applyExclusions, excluded.contains(where: { $0.matches(name) }) { priority = .ignored }
            return FileEntry(index: index, path: displayPath(base), size: file.size, priority: priority)
        }
        tree.load(entries)
        tree.expandAll()
    }

    private func exclusionMatchers() -> [TextMatcher] {
        guard preferences.downloads.excludedFileNamesEnabled else { return [] }
        return preferences.downloads.excludedFileNames.compactMap {
            TextMatcher(regex: "^" + FilterPatternFormat.wildcardToRegex($0) + "$")
        }
    }

    /// Renames a file or folder of the tree. Throws a user-facing message.
    func rename(_ node: FileNode, to newName: String) throws {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard name != node.name else { return }
        guard Self.isValidName(name) else {
            throw QbtError.InvalidArgument(message: String(localized: "The name is invalid: \"\(name)\""))
        }
        let parent = (node.path as NSString).deletingLastPathComponent
        let newDisplay = parent.isEmpty ? name : parent + "/" + name
        if node.isFolder {
            if contentLayout == .subfolder, commonRoot == nil, node.depth == 0 {
                rootOverride = name
                renamed = true
                rebuildTree()
                return
            }
            for file in tree.files(under: node) {
                let suffix = file.path.dropFirst(node.path.count)
                basePaths[file.fileIndex] = basePath(newDisplay + suffix)
            }
        } else {
            if basePaths.values.contains(basePath(newDisplay)) {
                throw QbtError.Conflict(message: String(localized: "The file already exists: '\(newDisplay)'."))
            }
            basePaths[node.fileIndex] = basePath(newDisplay)
        }
        renamed = true
        rebuildTree()
    }

    /// `Utils::Fs::isValidName` (non-Windows rules).
    static func isValidName(_ name: String) -> Bool {
        guard !name.isEmpty, name != ".", name != "..", name.utf8.count <= 255 else { return false }
        return !name.unicodeScalars.contains { $0.value < 32 || $0.value == 127 || $0 == "/" }
    }

    // MARK: Paths

    private func updateAutomaticPaths() {
        guard autoTMM else { return }
        savePath = categorySavePath(category)
        if useDownloadPath { downloadPath = categoryDownloadPath(category) }
    }

    private var defaultSavePath: String {
        preferences.downloads.savePath.isEmpty ? client.defaultSavePath() : preferences.downloads.savePath
    }

    func categorySavePath(_ name: String) -> String {
        guard !name.isEmpty else { return defaultSavePath }
        let explicit = categories[name]?.savePath ?? ""
        if explicit.hasPrefix("/") { return explicit }
        let parent = CategoryStore.ancestors(of: name).last.map(categorySavePath) ?? defaultSavePath
        let last = name.split(separator: "/").last.map(String.init) ?? name
        return parent + "/" + (explicit.isEmpty ? last : explicit)
    }

    private func categoryDownloadPath(_ name: String) -> String {
        let base = preferences.downloads.tempPath.isEmpty ? defaultSavePath + "/temp" : preferences.downloads.tempPath
        guard !name.isEmpty else { return base }
        if case .path(let path) = categories[name]?.downloadPath ?? .default, path.hasPrefix("/") { return path }
        return base + "/" + name
    }

    private func updateFreeSpace() {
        var url = URL(filePath: savePath)
        while !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)), url.pathComponents.count > 1 {
            url.deleteLastPathComponent()
        }
        freeSpace = client.freeDiskSpace(path: url.path(percentEncoded: false))
    }

    // MARK: Result

    var sizeDescription: String {
        guard metadata != nil, tree.wantedSize > 0 else { return String(localized: "Not available") }
        let free = freeSpace >= 0 ? UnitFormatter.size(freeSpace) : String(localized: "Unknown")
        return String(localized: "\(UnitFormatter.size(tree.wantedSize)) (Free space on disk: \(free))")
    }

    func makeParams() -> AddTorrentParams {
        var params = AddTorrentParams.sessionDefaults
        params.autoTmm = autoTMM
        if !autoTMM {
            params.savePath = savePath
            params.useDownloadPath = useDownloadPath
            params.downloadPath = useDownloadPath ? downloadPath : nil
        }
        params.category = category
        params.tags = tags
        params.stopped = !startTorrent
        params.stopCondition = startTorrent ? stopCondition : StopCondition.none
        params.addToQueueTop = addToQueueTop
        params.skipChecking = skipHashCheck
        params.sequential = sequential
        params.firstLastPiecePriority = firstLastPiece
        if metadata != nil {
            params.filePriorities = tree.filePriorities
            if renamed {
                // Send the final paths and keep them as they are.
                params.filePaths = basePaths.keys.sorted().compactMap { basePaths[$0].map(displayPath) }
                params.contentLayout = .original
            } else {
                params.contentLayout = contentLayout
            }
        } else {
            params.contentLayout = contentLayout
        }
        return params
    }

    /// Persists the dialog's remembered choices.
    func storeChoices(in gui: GUIPreferences) {
        gui.rememberLastSavePath = rememberLastSavePath
        if !autoTMM {
            gui.remember(savePath: savePath)
            if useDownloadPath { gui.remember(downloadPath: downloadPath) }
        }
        if setAsDefaultCategory { gui.defaultCategory = category }
        if neverShowAgain { gui.addTorrentDialogEnabled = false }
    }

    private static func initialTitle(for source: TorrentSource) -> String {
        switch source {
        case .url(let url):
            if let components = URLComponents(string: url), url.lowercased().hasPrefix("magnet:") {
                return components.queryItems?.first { $0.name == "dn" }?.value ?? String(localized: "Magnet link")
            }
            return URL(string: url)?.lastPathComponent ?? url
        case .file(let path):
            return ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        case .bytes:
            return String(localized: "Torrent")
        }
    }

    var isMagnet: Bool {
        if case .url(let url) = source { return !url.lowercased().hasPrefix("http") }
        return false
    }
}
