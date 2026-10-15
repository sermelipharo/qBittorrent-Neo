import SwiftUI

/// BitTorrent › Seeding Limits: ratio / seeding time / inactive seeding time
/// checkboxes and the "then" action (enabled when any limit is checked).
struct BitTorrentSeedingLimitsSection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Section("Seeding Limits") {
            LabeledContent {
                DecimalSpinControl(title: "When ratio reaches", value: $model.maxRatio, width: FeatureDesign.Width.wideSpinField)
                    .disabled(!model.maxRatioEnabled)
            } label: {
                Toggle("When ratio reaches", isOn: $model.maxRatioEnabled)
            }
            LimitRow(title: "When total seeding time reaches", isOn: $model.maxSeedingTimeEnabled,
                     value: $model.maxSeedingTime, range: 0...9_999_999, unit: String(localized: "min"))
            LimitRow(title: "When inactive seeding time reaches", isOn: $model.maxInactiveSeedingTimeEnabled,
                     value: $model.maxInactiveSeedingTime, range: 0...9_999_999, unit: String(localized: "min"))
            Picker("then", selection: $model.draft.bittorrent.maxRatioAct) {
                ForEach(PreferenceChoices.shareLimitActions, id: \.self) { action in
                    Text(PreferenceChoices.title(action)).tag(action)
                }
            }
            .disabled(!model.anySeedingLimitEnabled)
        }
    }
}
