import Foundation

/// The toolbar filter's "Filter by" choice.
enum TransferSearchScope: Hashable, CaseIterable, Sendable {
    case name
    case savePath
    case infohashV1
    case infohashV2

    var title: String {
        switch self {
        case .name: String(localized: "Name")
        case .savePath: String(localized: "Save Path")
        case .infohashV1: String(localized: "Info Hash v1")
        case .infohashV2: String(localized: "Info Hash v2")
        }
    }
}
