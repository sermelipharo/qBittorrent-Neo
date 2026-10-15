import Foundation

/// Tooltip of "Torrent stop condition:".
enum StopConditionHelp {
    static let text = String(localized: """
        None: No stop condition is set.
        Metadata received: Torrent will stop after metadata is received. \
        Torrents that have metadata initially will be added as stopped.
        Files checked: Torrent will stop after files are initially checked. \
        This will also download metadata if it wasn't there initially.
        """)
}
