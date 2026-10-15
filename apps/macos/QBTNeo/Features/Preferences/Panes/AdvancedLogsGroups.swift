import SwiftUI

/// Advanced › Logs & Diagnostics and Data & Recovery (expert).
struct AdvancedLogsGroups: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        let behavior = model.draft.behavior
        SettingsGroup(.logs) {
            Toggle(SettingsCatalog.title("file_log_enabled"), isOn: $model.draft.behavior.fileLogEnabled)
                .setting("file_log_enabled")
            Group {
                PathField(title: SettingsCatalog.key("file_log_path"), path: $model.draft.behavior.fileLogPath,
                          placeholder: FeatureDefaults.defaultLogFolder, panelMessage: String(localized: "Choose a save directory"))
                    .setting("file_log_path")
                LabeledContent {
                    SpinControl(title: SettingsCatalog.key("file_log_backup_enabled"), value: $model.draft.behavior.fileLogMaxSize,
                                range: 1...1_024_000, unit: UnitFormatter.kib)
                        .disabled(!behavior.fileLogBackupEnabled)
                } label: {
                    Toggle(SettingsCatalog.title("file_log_backup_enabled"), isOn: $model.draft.behavior.fileLogBackupEnabled)
                        .help("Creates an additional log file after the log file reaches the specified file size")
                }
                .setting("file_log_backup_enabled")
                LabeledContent {
                    HStack(spacing: Design.Spacing.small) {
                        SpinControl(title: SettingsCatalog.key("file_log_delete_old"), value: $model.draft.behavior.fileLogAge, range: 1...365)
                        Picker("Age unit", selection: $model.draft.behavior.fileLogAgeType) {
                            ForEach(PreferenceChoices.fileLogAgeTypes, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
                        }
                        .labelsHidden()
                        .fixedSize()
                    }
                    .disabled(!behavior.fileLogDeleteOld)
                } label: {
                    Toggle(SettingsCatalog.title("file_log_delete_old"), isOn: $model.draft.behavior.fileLogDeleteOld)
                }
                .setting("file_log_delete_old")
            }
            .disabled(!behavior.fileLogEnabled)
            Toggle(SettingsCatalog.title("performance_warning"), isOn: $model.draft.behavior.performanceWarning)
                .setting("performance_warning")
        }

        SettingsGroup(.dataRecovery) {
            Picker(SettingsCatalog.title("resume_data_storage_type"), selection: $model.draft.advanced.resumeDataStorageType) {
                ForEach(AdvancedChoices.resumeStorage, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .setting("resume_data_storage_type")
            SpinField(title: SettingsCatalog.key("save_resume_data_interval"), value: $model.draft.advanced.saveResumeDataInterval,
                      range: 0...Int64(Int32.max), unit: String(localized: "min"), special: .text(String(localized: "0 (disabled)")))
                .setting("save_resume_data_interval")
            SpinField(title: SettingsCatalog.key("save_statistics_interval"), value: $model.draft.advanced.saveStatisticsInterval,
                      range: 0...Int64(Int32.max), unit: String(localized: "min"), special: .text(String(localized: "0 (disabled)")))
                .setting("save_statistics_interval")
            SpinField(title: SettingsCatalog.key("BitTorrent/Session/ShutdownTimeout"), value: $model.draft.advanced.shutdownTimeout,
                      range: -1...Int64(Int32.max), unit: String(localized: "sec"), special: .text(String(localized: "-1 (unlimited)"), at: -1))
                .help("""
                    Sets the timeout for the session to be shut down gracefully, at which point it will be forcibly \
                    terminated. Note that this does not apply to the saving resume data time.
                    """)
                .setting("BitTorrent/Session/ShutdownTimeout")
        }
    }
}
