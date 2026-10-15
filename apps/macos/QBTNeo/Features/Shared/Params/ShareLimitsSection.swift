import SwiftUI

/// "Torrent share limits" (features.md §3.9) for a parameters template:
/// ratio, seeding time and inactive seeding time, each Default/From
/// category, Unlimited or a value. Inherited values are shown greyed.
struct ShareLimitsSection: View {
    @Binding var params: TorrentParamsTemplate
    let fromCategory: Bool
    let defaults: (ratio: Double, seeding: Int64, inactive: Int64)

    var body: some View {
        Section("Torrent share limits") {
            ShareLimitRow(
                title: "Ratio:", mode: $params.editorRatioMode, fromCategory: fromCategory,
                inherited: defaults.ratio >= 0 ? defaults.ratio.formatted(.number.precision(.fractionLength(2))) : ""
            ) {
                DecimalSpinControl(title: "Ratio:", value: $params.editorRatioValue)
            }
            ShareLimitRow(
                title: "Seeding time:", mode: $params.editorSeedingTimeMode, fromCategory: fromCategory,
                inherited: defaults.seeding >= 0 ? String(localized: "\(defaults.seeding) min") : ""
            ) {
                SpinControl(title: "Seeding time:", value: $params.editorSeedingTimeValue, range: 0...9_999_999, unit: String(localized: "min"))
            }
            ShareLimitRow(
                title: "Inactive seeding time:", mode: $params.editorInactiveTimeMode, fromCategory: fromCategory,
                inherited: defaults.inactive >= 0 ? String(localized: "\(defaults.inactive) min") : ""
            ) {
                SpinControl(
                    title: "Inactive seeding time:", value: $params.editorInactiveTimeValue, range: 0...9_999_999,
                    unit: String(localized: "min")
                )
            }
        }
    }
}
