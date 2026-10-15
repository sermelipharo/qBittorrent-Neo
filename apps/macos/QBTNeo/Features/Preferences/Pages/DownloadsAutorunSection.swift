import SwiftUI

/// Downloads › "Run external program".
struct DownloadsAutorunSection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Section {
            LabeledContent {
                CommitTextField(
                    title: "Run on torrent added:", text: $model.draft.downloads.autorunOnTorrentAddedProgram,
                    prompt: "/usr/local/bin/notify \"%N\"", trims: true
                )
                .labelsHidden()
                .disabled(!model.draft.downloads.autorunOnTorrentAddedEnabled)
            } label: {
                Toggle("Run on torrent added:", isOn: $model.draft.downloads.autorunOnTorrentAddedEnabled).settingAnchor("downloads.1")
            }
            LabeledContent {
                CommitTextField(
                    title: "Run on torrent finished:", text: $model.draft.downloads.autorunProgram,
                    prompt: "/usr/bin/open -R \"%F\"", trims: true
                )
                .labelsHidden()
                .disabled(!model.draft.downloads.autorunEnabled)
            } label: {
                Toggle("Run on torrent finished:", isOn: $model.draft.downloads.autorunEnabled).settingAnchor("downloads.2")
            }
        } header: {
            Text("Run external program")
        } footer: {
            Text(AutorunHelp.text)
                .settingsFootnote()
                .textSelection(.enabled)
        }
    }
}
