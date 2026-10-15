import SwiftUI

/// Settings › Downloads (preferences.md §2).
struct DownloadsPage: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        Form {
            Section("When adding a torrent") {
                Toggle("Display torrent content and some options", isOn: $gui.addTorrentDialogEnabled).settingAnchor("downloads.12")
                Toggle("Bring torrent dialog to the front", isOn: $gui.addTorrentDialogTopLevel).settingAnchor("downloads.13")
                    .disabled(!gui.addTorrentDialogEnabled)
                    .padding(.leading, Design.Spacing.xLarge)
                Picker("Torrent content layout:", selection: $model.draft.downloads.torrentContentLayout) {
                    ForEach(PreferenceChoices.contentLayouts, id: \.self) { layout in
                        Text(PreferenceChoices.title(layout)).tag(layout)
                    }
                }.settingAnchor("downloads.14")
                Toggle("Add to top of queue", isOn: $model.draft.downloads.addToTopOfQueue).settingAnchor("downloads.15")
                    .help("The torrent will be added to the top of the download queue")
                Toggle("Do not start the download automatically", isOn: $model.draft.downloads.addStoppedEnabled).settingAnchor("downloads.16")
                    .help("The torrent will be added to download list in a stopped state")
                Picker("Torrent stop condition:", selection: $model.draft.downloads.torrentStopCondition) {
                    ForEach(PreferenceChoices.stopConditions, id: \.self) { condition in
                        Text(PreferenceChoices.title(condition)).tag(condition)
                    }
                }.settingAnchor("downloads.17")
                .disabled(model.draft.downloads.addStoppedEnabled)
                .help(StopConditionHelp.text)
            }.settingAnchor("downloads.11")

            Section("When adding a duplicate torrent") {
                Toggle("Merge trackers to existing torrent", isOn: $model.draft.downloads.mergeTrackers).settingAnchor("downloads.19")
                Toggle("Ask to merge trackers for manually added torrent", isOn: $gui.confirmMergeTrackers).settingAnchor("downloads.20")
                    .disabled(!gui.addTorrentDialogEnabled)
            }.settingAnchor("downloads.18")

            CheckableSection(
                title: "Delete .torrent files afterwards", isOn: $model.deletesTorrentFiles,
                help: "Whether the .torrent file should be deleted after adding it"
            ) {
                Toggle("Also when addition is cancelled", isOn: $model.deletesCancelledTorrentFiles).settingAnchor("downloads.21")
                    .help("Also delete .torrent files whose addition was cancelled")
                if model.deletesTorrentFiles {
                    InlineMessage(text: String(localized: "Warning! Data loss possible!"), style: .warning)
                        .help("Files opened through file association are deleted as well.")
                }
            }

            Section {
                Toggle("Pre-allocate disk space for all files", isOn: $model.draft.downloads.preallocateAll).settingAnchor("downloads.22")
                    .help("Allocate full file sizes on disk before starting downloads, to minimize fragmentation. Only useful for HDDs.")
                Toggle("Append .!qB extension to incomplete files", isOn: $model.draft.downloads.incompleteFilesExt).settingAnchor("downloads.23")
                Toggle("Keep unselected files in \".unwanted\" folder", isOn: $model.draft.downloads.useUnwantedFolder)
                Toggle("Enable recursive download dialog", isOn: $gui.recursiveDownloadEnabled).settingAnchor("downloads.24")
                    .help("When a torrent is downloaded, offer to add torrents from any .torrent files found inside it")
            }

            DownloadsSavingSection(model: model)
            WatchedFoldersSection(model: model)

            CheckableSection(title: "Excluded file names", isOn: $model.draft.downloads.excludedFileNamesEnabled) {
                CommitTextEditor(title: "Excluded file names", text: $model.excludedFileNamesText, prompt: "*.exe\nreadme[0-9].txt")
                    .settingAnchor("downloads.26")
                    .help(ExcludedFileNamesHelp.text)
            }.settingAnchor("downloads.25")

            DownloadsEmailSection(model: model)
            DownloadsAutorunSection(model: model)
        }
    }
}
