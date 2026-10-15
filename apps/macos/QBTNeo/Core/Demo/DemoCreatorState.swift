import Foundation

/// Torrent creator tasks of the demo session; a task "hashes" for four
/// seconds, then finishes (or fails when the source path doesn't exist).
struct DemoCreatorState: Sendable {
    struct Task: Sendable {
        let id: String
        let params: TorrentCreatorParams
        let added: Date
        let sourceExists: Bool
    }

    static let duration = 4.0

    var tasks: [Task] = []

    mutating func add(_ params: TorrentCreatorParams) throws -> String {
        guard !params.sourcePath.isEmpty else { throw QbtError.InvalidArgument(message: "Source path is empty") }
        let id = UUID().uuidString.lowercased()
        let exists = FileManager.default.isReadableFile(atPath: params.sourcePath)
        tasks.append(Task(id: id, params: params, added: .now, sourceExists: exists))
        return id
    }

    func task(_ id: String) throws -> Task {
        guard let task = tasks.first(where: { $0.id == id }) else { throw QbtError.NotFound(message: "Task \(id) not found") }
        return task
    }

    static func record(_ task: Task, elapsed: Double) -> CreatorTask {
        let added = Int64(task.added.timeIntervalSince1970)
        let progress = min(max(elapsed - 0.3, 0) / duration, 1) * 100
        let status: CreatorTaskStatus = if !task.sourceExists, elapsed > 0.3 {
            .failed
        } else if elapsed < 0.3 {
            .queued
        } else {
            progress >= 100 ? .finished : .running
        }
        return CreatorTask(
            id: task.id, sourcePath: task.params.sourcePath, status: status,
            progress: status == .failed ? 0 : progress,
            errorMessage: status == .failed ? "Path to file/folder is not readable." : "",
            torrentFilePath: task.params.torrentFilePath, pieceSize: task.params.pieceSize > 0 ? task.params.pieceSize : 4 << 20,
            format: task.params.format, timeAdded: added, timeStarted: elapsed >= 0.3 ? added : 0,
            timeFinished: status == .finished ? added + Int64(duration) : 0,
            infoHash: status == .finished ? DemoRandom.hex(task.params.sourcePath, length: 40) : ""
        )
    }

    /// libtorrent-like automatic piece size: about 1,500 pieces, 16 KiB…16 MiB.
    static func autoPieceSize(_ total: Int64) -> Int64 {
        var size: Int64 = 16 * 1_024
        while size < 16 << 20, total / size > 1_500 { size *= 2 }
        return size
    }

    /// Sizes of the files a torrent of `path` would contain (hidden files skipped).
    static func fileSizes(at path: String) throws -> [Int64] {
        let url = URL(filePath: path)
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        let values = try url.resourceValues(forKeys: keys)
        if values.isRegularFile == true { return [Int64(values.fileSize ?? 0)] }
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else {
            return []
        }
        var sizes: [Int64] = []
        for case let file as URL in enumerator {
            let fileValues = try file.resourceValues(forKeys: keys)
            if fileValues.isRegularFile == true { sizes.append(Int64(fileValues.fileSize ?? 0)) }
        }
        return sizes
    }
}
