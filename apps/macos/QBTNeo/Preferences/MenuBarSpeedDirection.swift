import Foundation

/// Which transfer rates the menu bar item shows.
enum MenuBarSpeedDirection: Int, CaseIterable, Identifiable, Sendable {
    case both = 0
    case download = 1
    case upload = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .both: String(localized: "Download and upload")
        case .download: String(localized: "Download only")
        case .upload: String(localized: "Upload only")
        }
    }
}
