import Foundation
import Observation

/// "Manage Torrent Content" (qBittorrent 5.3, `TorrentContentLayoutDialog`):
/// every file of a torrent with its full relative path, editable one by one
/// or, for the selected files, through their common path. Apply renames the
/// changed files in one core call; renames that fail stay pending and the
/// first error is shown with the count of the others.
@Observable
@MainActor
final class ManageContentModel {
    let id: String
    let torrentName: String
    private(set) var rows: [ManageContentRow] = []
    private(set) var selection: Set<Int64> = []
    /// The text of the "Common path:" field. Typing rewrites the selected
    /// files' paths (`QLineEdit::textEdited`).
    var commonPath = "" {
        didSet { if !isPopulatingCommonPath, commonPath != oldValue { commonPathEdited() } }
    }
    private(set) var hasCommonPath = false
    private(set) var isApplying = false
    var showsRenameError = false
    private(set) var renameErrorMessage = ""

    @ObservationIgnored private let app: AppModel
    @ObservationIgnored private let initialSelection: [Int64]
    @ObservationIgnored private var edits = ContentLayoutEdits()
    @ObservationIgnored private var fileIndexes: [Int64] = []
    @ObservationIgnored private var rowOfFile: [Int64: Int] = [:]
    /// `m_commonPath`: the common path the last rewrite started from.
    @ObservationIgnored private var appliedCommonPath = ""
    @ObservationIgnored private var isPopulatingCommonPath = false
    @ObservationIgnored private var loading: Task<Void, Never>?

    /// `selectedFiles`: file indexes to select (the Content tab's "Batch
    /// Rename…"); none selects the first file.
    init(app: AppModel, id: String, torrentName: String, selectedFiles: [Int64] = []) {
        self.app = app
        self.id = id
        self.torrentName = torrentName
        initialSelection = selectedFiles
    }

    var hasChanges: Bool { rows.contains(where: \.isChanged) }
    var canApply: Bool { hasChanges && !isApplying }

    // MARK: Loading

    func load() async {
        if let loading { return await loading.value }
        let task = Task { await fetchFiles() }
        loading = task
        await task.value
    }

    private func fetchFiles() async {
        guard let client = app.client else { return }
        let id = id
        let files = (try? await CoreCall.run { try client.files(hash: id, indexes: []) }) ?? []
        show(files, keeping: [:])
        let wanted = Set(initialSelection)
        let initial = wanted.isEmpty ? Set(fileIndexes.prefix(1)) : wanted.intersection(fileIndexes)
        select(initial)
    }

    private func show(_ files: [TorrentFile], keeping kept: [Int64: String]) {
        let sorted = files.sorted { $0.index < $1.index }
        fileIndexes = sorted.map(\.index)
        rowOfFile = Dictionary(uniqueKeysWithValues: fileIndexes.enumerated().map { ($1, $0) })
        var keptRows: [Int: String] = [:]
        for (file, path) in kept {
            if let row = rowOfFile[file] { keptRows[row] = path }
        }
        edits.reload(paths: sorted.map(\.name), keeping: keptRows)
        selection.formIntersection(fileIndexes)
        publishRows()
    }

    private func publishRows() {
        rows = fileIndexes.indices.map { row in
            ManageContentRow(id: fileIndexes[row], path: edits.path(row), isChanged: edits.isChanged(row))
        }
    }

    // MARK: Editing

    /// The table's selection; refills the common path (`populateCommonPath`).
    func select(_ files: Set<Int64>) {
        guard files != selection else { return }
        selection = files
        populateCommonPath()
    }

    /// An edited Path cell.
    func setPath(_ text: String, forFile file: Int64) {
        guard let row = rowOfFile[file], edits.setPath(text, row: row) else { return }
        publishRows()
    }

    private var selectedRows: [Int] {
        selection.compactMap { rowOfFile[$0] }.sorted()
    }

    private func populateCommonPath() {
        let common = edits.commonPath(rows: selectedRows)
        appliedCommonPath = common ?? ""
        hasCommonPath = common != nil
        isPopulatingCommonPath = true
        commonPath = common ?? ""
        isPopulatingCommonPath = false
    }

    private func commonPathEdited() {
        let old = appliedCommonPath
        appliedCommonPath = ContentPath.clean(commonPath)
        let rows = selectedRows
        guard !rows.isEmpty else { return }
        let before = edits
        edits.replaceCommonPath(old, with: appliedCommonPath, rows: rows)
        if edits != before { publishRows() }
    }

    // MARK: Applying

    func apply() async {
        guard canApply, let client = app.client else { return }
        isApplying = true
        defer { isApplying = false }
        let renames = edits.changes.map { FileRename(index: fileIndexes[$0.row], newPath: $0.path) }
        let pending = Dictionary(uniqueKeysWithValues: renames.map { ($0.index, $0.newPath) })
        let id = id
        do {
            let failures = try await client.renameFiles(hash: id, renames: renames)
            let files = (try? await CoreCall.run { try client.files(hash: id, indexes: []) }) ?? []
            var kept: [Int64: String] = [:]
            for failure in failures {
                if let path = pending[failure.index] { kept[failure.index] = path }
            }
            show(files, keeping: kept)
            populateCommonPath()
            if let first = failures.first { presentRenameError(first.message, count: failures.count) }
        } catch {
            presentRenameError(error.userMessage, count: 1)
        }
        app.refreshSoon()
    }

    /// `renameFailed`: the first message, then how many others failed.
    private func presentRenameError(_ message: String, count: Int) {
        var text = message
        if count > 1 {
            let more = count - 1
            text += "\n" + String(localized: "There are \(more) more renaming error(s).",
                                  comment: "There are 5 more renaming errors.")
        }
        renameErrorMessage = text
        showsRenameError = true
    }
}
