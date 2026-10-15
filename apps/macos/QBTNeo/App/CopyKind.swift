import Foundation

/// Entries of the transfer list's Copy submenu.
enum CopyKind: CaseIterable {
    case name
    case infohashV1
    case infohashV2
    case magnet
    case torrentID
    case comment
    case contentPath

    var title: String {
        switch self {
        case .name: String(localized: "Name")
        case .infohashV1: String(localized: "Info Hash v1")
        case .infohashV2: String(localized: "Info Hash v2")
        case .magnet: String(localized: "Magnet Link")
        case .torrentID: String(localized: "Torrent ID")
        case .comment: String(localized: "Comment")
        case .contentPath: String(localized: "Content Path")
        }
    }

    @MainActor
    func value(of item: TorrentItem) -> String? {
        switch self {
        case .name: item.name
        case .infohashV1: item.infohashV1
        case .infohashV2: item.infohashV2
        case .magnet: item.magnetURI
        case .torrentID: item.id
        case .comment: item.comment
        case .contentPath: item.contentPath
        }
    }
}
