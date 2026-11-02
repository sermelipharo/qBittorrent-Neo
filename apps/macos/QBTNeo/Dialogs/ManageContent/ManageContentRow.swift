import Foundation

/// One file of the Manage Torrent Content table.
struct ManageContentRow: Identifiable, Equatable, Sendable {
    /// The torrent's file index.
    let id: Int64
    let path: String
    /// Edited and not applied yet (drawn in italics).
    let isChanged: Bool
}
