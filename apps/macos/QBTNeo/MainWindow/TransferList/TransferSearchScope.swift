import Foundation

/// The toolbar filter's "Filter by" choice.
enum TransferSearchScope: Hashable, CaseIterable, Sendable {
    case name
    case savePath

    var title: String {
        switch self {
        case .name: String(localized: "Name")
        case .savePath: String(localized: "Save Path")
        }
    }
}
