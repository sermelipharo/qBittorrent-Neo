import SwiftUI

/// Settings › Speed (preferences.md §4). Limits are shown in KiB/s.
struct SpeedPage: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Form {
            Section("Global Rate Limits") {
                SpinField(title: "Upload:", value: $model.uploadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
                SpinField(title: "Download:", value: $model.downloadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
            }
            Section {
                SpinField(title: "Upload:", value: $model.altUploadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
                SpinField(title: "Download:", value: $model.altDownloadLimitKiB, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
            } header: {
                Label("Alternative Rate Limits", systemImage: "tortoise")
            }

            CheckableSection(title: "Schedule the use of alternative rate limits", isOn: $model.draft.speed.schedulerEnabled) {
                DatePicker("From:", selection: $model.scheduleFrom, displayedComponents: .hourAndMinute)
                    .help("Start time")
                DatePicker("To:", selection: $model.scheduleTo, displayedComponents: .hourAndMinute)
                    .help("End time")
                Picker("When:", selection: $model.draft.speed.schedulerDays) {
                    ForEach(PreferenceChoices.schedulerDays, id: \.self) { days in
                        Text(PreferenceChoices.title(days)).tag(days)
                    }
                }
                if let error = model.schedulerError {
                    InlineMessage(text: error)
                }
            }

            Section("Rate Limits Settings") {
                Toggle("Apply rate limit to µTP protocol", isOn: $model.draft.speed.limitUtpRate)
                Toggle("Apply rate limit to transport overhead", isOn: $model.draft.speed.limitTcpOverhead)
                Toggle("Apply rate limit to peers on LAN", isOn: $model.draft.speed.limitLanPeers)
            }
        }
    }
}
