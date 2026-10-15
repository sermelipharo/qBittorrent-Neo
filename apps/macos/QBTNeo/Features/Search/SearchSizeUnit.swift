import Foundation

/// Units of the "Size:" range filter (1024-based).
enum SearchSizeUnit: Int, CaseIterable, Identifiable {
    case bytes, kib, mib, gib, tib, pib, eib

    var id: Int { rawValue }

    var title: String { UnitFormatter.unitName(UnitFormatter.Unit.allCases[rawValue]) }

    func bytes(_ value: Double) -> Double {
        value * pow(1_024, Double(rawValue))
    }
}
