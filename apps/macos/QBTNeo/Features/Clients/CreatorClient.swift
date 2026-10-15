import Foundation

/// Torrent creator calls of the core facade (`api_creator.rs`). Signatures
/// match the generated bindings, so `App` conforms without glue.
protocol CreatorClient: AnyObject, Sendable {
    func creatorAddTask(params: TorrentCreatorParams) throws -> String
    func creatorTasks() -> [CreatorTask]
    func creatorTask(id: String) throws -> CreatorTask
    func creatorTorrentFile(id: String) throws -> Data
    func creatorDeleteTask(id: String) throws
    func creatorAutoPieceSize(totalSize: Int64, format: TorrentFormat) -> Int64
    /// "Calculate number of pieces" (walks the source; piece size 0 = automatic).
    func creatorCalculatePieces(sourcePath: String, pieceSize: Int64, format: TorrentFormat) async throws -> Int64
}
