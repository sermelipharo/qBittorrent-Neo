import Foundation

/// The "Supported parameters" label of "Run external program".
enum AutorunHelp {
    static let text = String(localized: """
        Supported parameters (case sensitive):
            %N: Torrent name
            %L: Category
            %G: Tags (separated by comma)
            %F: Content path (same as root path for multifile torrent)
            %R: Root path (first torrent subdirectory path)
            %D: Save path
            %C: Number of files
            %Z: Torrent size (bytes)
            %T: Current tracker
            %I: Info hash v1 (or '-' if unavailable)
            %J: Info hash v2 (or '-' if unavailable)
            %K: Torrent ID (either sha-1 info hash for v1 torrent or truncated sha-256 info hash for v2/hybrid torrent)
            %M: Comment
        Tip: Encapsulate parameter with quotation marks to avoid text being cut off at whitespace (e.g., "%N")
        """)
}
