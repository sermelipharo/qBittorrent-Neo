import Foundation

/// Mode combo of the share limits widget (features.md §3.9): `Default` /
/// `From category` (-2), `Unlimited` (-1) or `Set to` a value.
enum ParamsLimitMode: Hashable, CaseIterable {
    case inherit
    case unlimited
    case value

    init(_ raw: Double) {
        self = raw <= -2 ? .inherit : (raw < 0 ? .unlimited : .value)
    }

    init(_ raw: Int64) {
        self.init(Double(raw))
    }

    /// Raw value for this mode, keeping `current` when it is already a value.
    func raw(current: Double, initial: Double) -> Double {
        switch self {
        case .inherit: -2
        case .unlimited: -1
        case .value: current >= 0 ? current : initial
        }
    }

    func raw(current: Int64, initial: Int64) -> Int64 {
        Int64(raw(current: Double(current), initial: Double(initial)))
    }

    /// "Default" without a category, "From category" with one.
    func title(fromCategory: Bool) -> String {
        switch self {
        case .inherit:
            if fromCategory {
                String(localized: "From category")
            } else {
                String(localized: "Default")
            }
        case .unlimited: String(localized: "Unlimited")
        case .value: String(localized: "Set to")
        }
    }
}
