import Foundation

/// Tools › On Downloads Done (exclusive group). Hibernate is unavailable on macOS.
enum CompletionAction: Int, CaseIterable, Identifiable, Sendable {
    case doNothing
    case exitApp
    case suspend
    case reboot
    case shutdown

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .doNothing: String(localized: "Do nothing")
        case .exitApp: String(localized: "Exit qBittorrent Neo")
        case .suspend: String(localized: "Suspend System")
        case .reboot: String(localized: "Reboot System")
        case .shutdown: String(localized: "Shutdown System")
        }
    }
}
