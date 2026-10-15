import Foundation
import UniformTypeIdentifiers

/// Open panels presented by the main window.
enum FileImportRequest: Identifiable {
    case torrentFiles
    case setLocation(ids: [String], startPath: String)
    case exportTorrents(ids: [String])

    var id: String {
        switch self {
        case .torrentFiles: "torrentFiles"
        case .setLocation(let ids, _): "location-\(ids.joined())"
        case .exportTorrents(let ids): "export-\(ids.joined())"
        }
    }

    var contentTypes: [UTType] {
        switch self {
        case .torrentFiles: [.torrent]
        case .setLocation, .exportTorrents: [.folder]
        }
    }

    var allowsMultipleSelection: Bool {
        if case .torrentFiles = self { return true }
        return false
    }
}

extension UTType {
    /// BitTorrent metainfo files (declared in Info.plist).
    static let torrent = UTType(importedAs: "org.bittorrent.torrent", conformingTo: .data)
}
