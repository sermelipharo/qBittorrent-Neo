import SwiftUI

/// Transfers › Files › Run a Program (advanced), with the parameter help in a disclosure.
struct RunProgramGroup: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        let downloads = model.draft.downloads
        SettingsGroup(.runProgram) {
            commandRow("autorun_on_torrent_added_enabled", isOn: $model.draft.downloads.autorunOnTorrentAddedEnabled,
                       command: $model.draft.downloads.autorunOnTorrentAddedProgram, prompt: "/usr/local/bin/notify \"%N\"",
                       enabled: downloads.autorunOnTorrentAddedEnabled)
            commandRow("autorun_enabled", isOn: $model.draft.downloads.autorunEnabled, command: $model.draft.downloads.autorunProgram,
                       prompt: "/usr/bin/open -R \"%F\"", enabled: downloads.autorunEnabled)
            DisclosureGroup("Supported parameters") {
                Text(AutorunHelp.text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func commandRow(_ id: String, isOn: Binding<Bool>, command: Binding<String>, prompt: String, enabled: Bool) -> some View {
        LabeledContent {
            HStack(spacing: Design.Spacing.small) {
                Toggle(SettingsCatalog.title(id), isOn: isOn)
                    .labelsHidden()
                CommitTextField(title: SettingsCatalog.key(id), text: command, prompt: prompt, trims: true)
                    .labelsHidden()
                    .disabled(!enabled)
            }
        } label: {
            Text(SettingsCatalog.title(id))
        }
        .setting(id)
    }
}
