import SwiftUI

/// Settings › Speed: how fast, and when to slow down. Limits are shown in KiB/s.
struct SpeedPane: View {
    @Bindable var model: PreferencesModel
    @Environment(AppModel.self) private var app

    var body: some View {
        SettingsPaneView(.speed, model: model) {
            SpeedHeader()
        } content: {
            SettingsGroup(.globalLimits) {
                limit("dl_limit", value: $model.downloadLimitKiB)
                limit("up_limit", value: $model.uploadLimitKiB)
            }

            SettingsGroup(.alternativeLimits) {
                limit("alt_dl_limit", value: $model.altDownloadLimitKiB)
                limit("alt_up_limit", value: $model.altUploadLimitKiB)
            } footer: {
                SettingFootnote(text: String(localized: "Turn on with the tortoise button in the toolbar or status bar, or on a schedule."))
            }

            SettingsGroup(.schedule) {
                Toggle(SettingsCatalog.title("scheduler_enabled"), isOn: $model.draft.speed.schedulerEnabled)
                    .setting("scheduler_enabled")
            } content: {
                if model.draft.speed.schedulerEnabled {
                    DatePicker(SettingsCatalog.title("schedule_from_hour"), selection: $model.scheduleFrom, displayedComponents: .hourAndMinute)
                        .help("Start time")
                        .setting("schedule_from_hour")
                    DatePicker(SettingsCatalog.title("schedule_to_hour"), selection: $model.scheduleTo, displayedComponents: .hourAndMinute)
                        .help("End time")
                        .setting("schedule_to_hour")
                    Picker(SettingsCatalog.title("scheduler_days"), selection: $model.draft.speed.schedulerDays) {
                        ForEach(PreferenceChoices.schedulerDays, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
                    }
                    .fixedSize()
                    .setting("scheduler_days")
                    if let error = model.schedulerError {
                        InlineMessage(text: error)
                    }
                }
            }

            SettingsGroup(.rateLimitSettings) {
                Toggle(SettingsCatalog.title("limit_utp_rate"), isOn: $model.draft.speed.limitUtpRate)
                    .setting("limit_utp_rate")
            } content: {
                Toggle(SettingsCatalog.title("limit_tcp_overhead"), isOn: $model.draft.speed.limitTcpOverhead)
                    .setting("limit_tcp_overhead")
                Toggle(SettingsCatalog.title("limit_lan_peers"), isOn: $model.draft.speed.limitLanPeers)
                    .setting("limit_lan_peers")
            }
        }
    }

    private func limit(_ id: String, value: Binding<Int64>) -> some View {
        SpinField(title: SettingsCatalog.key(id), value: value, range: 0...2_000_000, unit: UnitFormatter.kibPerSecond, special: .infinity())
            .setting(id)
    }
}
