import Foundation

/// Which parts of a transfer-list row take the torrent state's color ("Color
/// by state:"). One choice instead of two dependent toggles: the options are
/// exclusive, and "Whole row" covers the text and the progress bar together.
/// The state icon next to the name is always colored.
enum StateColorScope: Int, CaseIterable, Identifiable, Sendable {
    case off = 0
    case wholeRow = 1
    case name = 2
    case progressBar = 3
    case status = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .off: String(localized: "None")
        case .wholeRow: String(localized: "Whole row")
        case .name: String(localized: "Name only")
        case .progressBar: String(localized: "Progress bar only")
        case .status: String(localized: "Status only")
        }
    }

    /// Whether the text of `column` takes the state color.
    func colorsText(of column: TransferColumn) -> Bool {
        switch self {
        case .wholeRow: true
        case .name: column == .name
        case .status: column == .status
        case .off, .progressBar: false
        }
    }

    var colorsProgressBar: Bool { self == .wholeRow || self == .progressBar }

    /// The choice matching qBittorrent's two former settings, "Use different
    /// text colors by torrent states" (default on) and "Make progress bars
    /// follow text colors": colored text becomes the whole row, otherwise
    /// nothing is colored. Nil when neither was ever stored.
    static func migrated(useStateColors: Bool?, progressBarFollows: Bool?) -> Self? {
        guard useStateColors != nil || progressBarFollows != nil else { return nil }
        return (useStateColors ?? true) ? .wholeRow : .off
    }
}
