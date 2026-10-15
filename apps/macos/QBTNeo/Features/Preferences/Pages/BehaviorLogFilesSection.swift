import SwiftUI

/// Behavior › Log Files (checkable group).
struct BehaviorLogFilesSection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        CheckableSection(title: "Log Files", isOn: $model.draft.behavior.fileLogEnabled) {
            PathField(
                title: "Save path:", path: $model.draft.behavior.fileLogPath,
                placeholder: FeatureDefaults.defaultLogFolder, panelMessage: String(localized: "Choose a save directory")
            )
            LabeledContent {
                SpinControl(title: "Backup the log file after:", value: $model.draft.behavior.fileLogMaxSize, range: 1...1_024_000, unit: UnitFormatter.kib)
                    .settingAnchor("behavior.12")
                    .disabled(!model.draft.behavior.fileLogBackupEnabled)
            } label: {
                Toggle("Backup the log file after:", isOn: $model.draft.behavior.fileLogBackupEnabled).settingAnchor("behavior.13")
                    .help("Creates an additional log file after the log file reaches the specified file size")
            }
            LabeledContent {
                HStack(spacing: Design.Spacing.small) {
                    SpinControl(title: "Delete backup logs older than:", value: $model.draft.behavior.fileLogAge, range: 1...365)
                        .settingAnchor("behavior.14")
                    Picker("Age unit", selection: $model.draft.behavior.fileLogAgeType) {
                        ForEach(PreferenceChoices.fileLogAgeTypes, id: \.self) { unit in
                            Text(PreferenceChoices.title(unit)).tag(unit)
                        }
                    }.settingAnchor("behavior.15")
                    .labelsHidden()
                    .fixedSize()
                }
                .disabled(!model.draft.behavior.fileLogDeleteOld)
            } label: {
                Toggle("Delete backup logs older than:", isOn: $model.draft.behavior.fileLogDeleteOld).settingAnchor("behavior.16")
            }
        }.settingAnchor("behavior.11")
    }
}
