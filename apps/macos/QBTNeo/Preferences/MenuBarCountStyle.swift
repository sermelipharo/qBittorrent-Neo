import Foundation

/// How the menu bar item shows the number of torrents.
enum MenuBarCountStyle: Int, CaseIterable, Identifiable, Sendable {
    case activeOfTotal = 0
    case active = 1
    case total = 2

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .activeOfTotal: String(localized: "Active of total (3/12)")
        case .active: String(localized: "Active")
        case .total: String(localized: "Total")
        }
    }
}
