import Foundation

/// Rows of the separate "Tracker status" section
/// (`TransferListFilters/SeparateTrackerStatusFilter`).
enum TrackerStatusFilter: Int, CaseIterable, Hashable, Sendable {
    case all
    case warning
    case trackerError
    case otherError

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .warning: String(localized: "Warning")
        case .trackerError: String(localized: "Tracker error")
        case .otherError: String(localized: "Other error")
        }
    }

    var systemImage: String {
        switch self {
        case .all: "antenna.radiowaves.left.and.right"
        case .warning: "exclamationmark.triangle"
        case .trackerError, .otherError: "xmark.octagon"
        }
    }
}
