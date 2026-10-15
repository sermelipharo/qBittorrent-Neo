import Foundation

/// Transfer-list double-click / Return action (`DblClOnTorDl` / `DblClOnTorFn`).
enum DoubleClickAction: Int, CaseIterable, Identifiable, Sendable {
    case toggleStop = 0
    case openDestination = 1
    case previewFile = 2
    case noAction = 3
    case showOptions = 4

    var id: Int { rawValue }

    /// Combo order used by the Options dialog.
    static let menuOrder: [Self] = [.toggleStop, .openDestination, .previewFile, .showOptions, .noAction]

    var title: String {
        switch self {
        case .toggleStop: String(localized: "Start / stop torrent")
        case .openDestination: String(localized: "Open destination folder")
        case .previewFile: String(localized: "Preview file, otherwise open destination folder")
        case .noAction: String(localized: "No action")
        case .showOptions: String(localized: "Open torrent options dialog")
        }
    }
}
