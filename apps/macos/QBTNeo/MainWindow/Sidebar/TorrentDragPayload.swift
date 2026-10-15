import Foundation

/// Torrents dragged from the transfer list onto a sidebar category or tag.
/// Encoded as plain text with a private prefix so it never looks like a link.
enum TorrentDragPayload {
    private static let prefix = "qbtneo-torrents:"

    static func encode(_ ids: [String]) -> String {
        prefix + ids.joined(separator: ",")
    }

    static func decode(_ strings: [String]) -> [String] {
        strings.flatMap { string -> [String] in
            guard string.hasPrefix(prefix) else { return [] }
            return string.dropFirst(prefix.count).split(separator: ",").map(String.init)
        }
    }
}
