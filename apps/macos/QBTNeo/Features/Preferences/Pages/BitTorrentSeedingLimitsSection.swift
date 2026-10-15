import SwiftUI

/// BitTorrent › Seeding Limits: ratio / seeding time / inactive seeding time
/// checkboxes and the "then" action (enabled when any limit is checked).
struct BitTorrentSeedingLimitsSection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Section("Seeding Limits") {
            LabeledContent {
                DecimalSpinControl(title: "When ratio reaches", value: $model.maxRatio, width: FeatureDesign.Width.wideSpinField)
                    .settingAnchor("bittorrent.19")
                    .disabled(!model.maxRatioEnabled)
            } label: {
                Toggle("When ratio reaches", isOn: $model.maxRatioEnabled).settingAnchor("bittorrent.20")
            }
            LimitRow(title: "When total seeding time reaches", isOn: $model.maxSeedingTimeEnabled,
                     value: $model.maxSeedingTime, range: 0...9_999_999, unit: String(localized: "min")).settingAnchor("bittorrent.21")
            LimitRow(title: "When inactive seeding time reaches", isOn: $model.maxInactiveSeedingTimeEnabled,
                     value: $model.maxInactiveSeedingTime, range: 0...9_999_999, unit: String(localized: "min")).settingAnchor("bittorrent.22")
            Picker("then", selection: $model.draft.bittorrent.maxRatioAct) {
                ForEach(PreferenceChoices.shareLimitActions, id: \.self) { action in
                    Text(PreferenceChoices.title(action)).tag(action)
                }
            }.settingAnchor("bittorrent.23")
            .disabled(!model.anySeedingLimitEnabled)
        }.settingAnchor("bittorrent.18")
    }
}
