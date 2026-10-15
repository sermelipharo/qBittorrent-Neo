import Foundation

/// The single, data-driven list of every setting (docs/design/settings-ia.md
/// §8, §10): pane, section, tier, label, explanation, search keywords and the
/// stored keys each row edits. It drives search, tier visibility, the
/// hidden-changes counter and the coverage check. Array order is pane and
/// section order. Built once; about 260 small values.
@MainActor
enum SettingsCatalog {
    static let all: [SettingSpec] = general + interface + transfers + searchRSS + speed + network + privacy + remote + advanced

    private static let byID: [String: SettingSpec] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    static func spec(_ id: String) -> SettingSpec? {
        byID[id]
    }

    /// The row label of a setting (views use it so labels and search can't drift).
    static func title(_ id: String) -> String {
        byID[id]?.title ?? id
    }

    static func help(_ id: String) -> String? {
        byID[id]?.help
    }

    /// Specs whose rows are hidden while "Show advanced settings" is off, per pane.
    static func advancedSpecs(in pane: SettingsPane) -> [SettingSpec] {
        all.filter { $0.pane == pane && $0.tier.hasRow && $0.needsAdvanced }
    }
}
