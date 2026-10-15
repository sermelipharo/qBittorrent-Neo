import SwiftUI

/// Settings › Speed (preferences.md §4). Limits are shown in KiB/s.
struct SpeedPage: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Form {
            Section("Global Rate Limits") {
                SpinField(title: "Upload:", value: $model.uploadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
                    .settingAnchor("speed.2")
                SpinField(title: "Download:", value: $model.downloadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
                    .settingAnchor("speed.3")
            }.settingAnchor("speed.1")
            Section {
                SpinField(title: "Upload:", value: $model.altUploadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
                    .settingAnchor("speed.4")
                SpinField(title: "Download:", value: $model.altDownloadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
                    .settingAnchor("speed.5")
            } header: {
                Label("Alternative Rate Limits", systemImage: Symbol.tortoise)
            }

            CheckableSection(title: "Schedule the use of alternative rate limits", isOn: $model.draft.speed.schedulerEnabled) {
                DatePicker("From:", selection: $model.scheduleFrom, displayedComponents: .hourAndMinute).settingAnchor("speed.7")
                    .help("Start time")
                DatePicker("To:", selection: $model.scheduleTo, displayedComponents: .hourAndMinute).settingAnchor("speed.8")
                    .help("End time")
                Picker("When:", selection: $model.draft.speed.schedulerDays) {
                    ForEach(PreferenceChoices.schedulerDays, id: \.self) { days in
                        Text(PreferenceChoices.title(days)).tag(days)
                    }
                }.settingAnchor("speed.9")
                if let error = model.schedulerError {
                    InlineMessage(text: error)
                }
            }.settingAnchor("speed.6")

            Section("Rate Limits Settings") {
                Toggle("Apply rate limit to µTP protocol", isOn: $model.draft.speed.limitUtpRate).settingAnchor("speed.11")
                Toggle("Apply rate limit to transport overhead", isOn: $model.draft.speed.limitTcpOverhead).settingAnchor("speed.12")
                Toggle("Apply rate limit to peers on LAN", isOn: $model.draft.speed.limitLanPeers).settingAnchor("speed.13")
            }.settingAnchor("speed.10")
        }
    }
}
