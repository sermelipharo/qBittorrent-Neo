import Foundation

extension DemoClient: CreatorClient {
    private var store: DemoFeatureStore { .shared }

    func creatorAddTask(params: TorrentCreatorParams) throws -> String {
        try store.creator.withLock { try $0.add(params) }
    }

    func creatorTasks() -> [CreatorTask] {
        store.creator.withLock { state in
            state.tasks.map { DemoCreatorState.record($0, elapsed: store.elapsed(since: $0.added)) }
        }
    }

    func creatorTask(id: String) throws -> CreatorTask {
        try store.creator.withLock { state in
            let task = try state.task(id)
            return DemoCreatorState.record(task, elapsed: store.elapsed(since: task.added))
        }
    }

    func creatorTorrentFile(id: String) throws -> Data {
        let record = try creatorTask(id: id)
        guard record.status == .finished else { throw QbtError.Conflict(message: "Torrent creation is still unfinished.") }
        let name = URL(filePath: record.sourcePath).lastPathComponent
        return Data("d10:created by18:qBittorrent Neo 0.14:infod4:name\(name.utf8.count):\(name)12:piece lengthi\(record.pieceSize)eee".utf8)
    }

    func creatorDeleteTask(id: String) throws {
        store.creator.withLock { $0.tasks.removeAll { $0.id == id } }
    }

    func creatorAutoPieceSize(totalSize: Int64, format: TorrentFormat) -> Int64 {
        DemoCreatorState.autoPieceSize(totalSize)
    }

    func creatorCalculatePieces(sourcePath: String, pieceSize: Int64, format: TorrentFormat) async throws -> Int64 {
        try await Task.sleep(for: .milliseconds(400))
        let sizes = try DemoCreatorState.fileSizes(at: sourcePath)
        let total = sizes.reduce(0, +)
        let piece = pieceSize > 0 ? pieceSize : DemoCreatorState.autoPieceSize(total)
        guard piece > 0 else { return 0 }
        if format == .v1 { return (total + piece - 1) / piece }
        return sizes.reduce(0) { $0 + ($1 + piece - 1) / piece }
    }
}
