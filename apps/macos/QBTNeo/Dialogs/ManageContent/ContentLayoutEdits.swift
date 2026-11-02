import Foundation

/// The edits of the Manage Torrent Content dialog (qBittorrent 5.3,
/// `TorrentContentLayoutModel`): the torrent's file paths by row, the
/// changed ones, and the "Common path" rewrite of selected rows
/// (`TorrentContentLayoutDialog::onCommonPathEdited`).
struct ContentLayoutEdits: Equatable, Sendable {
    /// The paths the torrent has, by row.
    private(set) var originals: [String]
    /// Edited paths by row; never equal to the original.
    private(set) var changed: [Int: String] = [:]

    init(paths: [String] = []) {
        originals = paths
    }

    var count: Int { originals.count }
    var hasChanges: Bool { !changed.isEmpty }

    func path(_ row: Int) -> String { changed[row] ?? originals[row] }
    func isChanged(_ row: Int) -> Bool { changed[row] != nil }

    /// The changed rows in row order.
    var changes: [(row: Int, path: String)] {
        changed.sorted { $0.key < $1.key }.map { (row: $0.key, path: $0.value) }
    }

    /// `setData`: the cleaned path; the original path drops the change.
    /// Returns whether the row changed.
    @discardableResult
    mutating func setPath(_ text: String, row: Int) -> Bool {
        guard originals.indices.contains(row) else { return false }
        let path = ContentPath.clean(text)
        guard path != self.path(row) else { return false }
        changed[row] = path == originals[row] ? nil : path
        return true
    }

    /// The common path of `rows`; nil without rows.
    func commonPath(rows: some Sequence<Int>) -> String? {
        ContentPath.common(rows.lazy.filter { originals.indices.contains($0) }.map { path($0) })
    }

    /// Moves every row from under `old` to under `new` (`oldCommonPath.relativePathOf`).
    mutating func replaceCommonPath(_ old: String, with new: String, rows: some Sequence<Int>) {
        for row in rows where originals.indices.contains(row) {
            setPath(ContentPath.join(new, ContentPath.relative(path(row), to: old)), row: row)
        }
    }

    /// After applying: the torrent's current paths, with `kept` edits (renames
    /// that failed) still pending.
    mutating func reload(paths: [String], keeping kept: [Int: String]) {
        originals = paths
        changed = kept.filter { paths.indices.contains($0.key) && paths[$0.key] != $0.value }
    }
}
