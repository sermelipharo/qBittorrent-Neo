import Foundation

/// Mode of one share-limit row: Default (-2), Unlimited (-1) or Set to.
enum ShareLimitMode: Int, CaseIterable, Identifiable, Sendable {
    case `default`
    case unlimited
    case set

    var id: Int { rawValue }

    init(sentinel value: Double) {
        self = value == -2 ? .default : (value < 0 ? .unlimited : .set)
    }

    func title(fromCategory: Bool) -> String {
        switch self {
        case .default:
            if fromCategory { String(localized: "From category") } else { String(localized: "Default") }
        case .unlimited: String(localized: "Unlimited")
        case .set: String(localized: "Set to")
        }
    }
}
