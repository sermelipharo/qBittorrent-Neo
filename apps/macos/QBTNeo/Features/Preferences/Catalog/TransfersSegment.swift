import Foundation

/// The inner segments of the Transfers pane.
enum TransfersSegment: String, CaseIterable, Identifiable {
    case adding
    case files
    case seedingQueue
    case searchRSS

    var id: Self { self }

    var title: String {
        switch self {
        case .adding: String(localized: "Adding")
        case .files: String(localized: "Files")
        case .seedingQueue: String(localized: "Seeding & Queue")
        case .searchRSS: String(localized: "Search & RSS")
        }
    }
}
