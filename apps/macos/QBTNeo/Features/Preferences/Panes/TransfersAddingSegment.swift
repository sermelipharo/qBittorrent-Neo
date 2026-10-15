import SwiftUI

/// Transfers › Adding: save location, adding options, watched folders,
/// duplicates, .torrent files and extra trackers.
struct TransfersAddingSegment: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        let downloads = model.draft.downloads
        SettingsGroup(.saveLocation) {
            PathField(title: SettingsCatalog.key("save_path"), path: $model.draft.downloads.savePath,
                      panelMessage: String(localized: "Choose a save directory"))
                .setting("save_path")
            LabeledContent {
                VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                    HStack(spacing: Design.Spacing.small) {
                        Toggle(SettingsCatalog.title("temp_path_enabled"), isOn: $model.draft.downloads.tempPathEnabled)
                            .labelsHidden()
                        PathControl(title: SettingsCatalog.key("temp_path_enabled"), path: $model.draft.downloads.tempPath,
                                    placeholder: downloads.savePath + "/temp", panelMessage: String(localized: "Choose a save directory"))
                            .disabled(!downloads.tempPathEnabled)
                    }
                    if let help = SettingsCatalog.help("temp_path_enabled") {
                        SettingFootnote(text: help)
                    }
                }
            } label: {
                Text(SettingsCatalog.title("temp_path_enabled"))
            }
            .setting("temp_path_enabled", help: false)
        }

        SettingsGroup(.addingTorrents) {
            Toggle(SettingsCatalog.title("AddNewTorrentDialog/Enabled"), isOn: $gui.addTorrentDialogEnabled)
                .setting("AddNewTorrentDialog/Enabled")
        } content: {
            Toggle(SettingsCatalog.title("AddNewTorrentDialog/TopLevel"), isOn: $gui.addTorrentDialogTopLevel)
                .disabled(!gui.addTorrentDialogEnabled)
                .setting("AddNewTorrentDialog/TopLevel", indented: true)
            Toggle(SettingsCatalog.title("add_stopped_enabled"), isOn: startsAutomatically)
                .help("The torrent will be added to download list in a stopped state")
                .setting("add_stopped_enabled")
            Picker(SettingsCatalog.title("torrent_stop_condition"), selection: $model.draft.downloads.torrentStopCondition) {
                ForEach(PreferenceChoices.stopConditions, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
            }
            .fixedSize()
            .disabled(downloads.addStoppedEnabled)
            .help(StopConditionHelp.text)
            .setting("torrent_stop_condition")
            Picker(SettingsCatalog.title("torrent_content_layout"), selection: $model.draft.downloads.torrentContentLayout) {
                ForEach(PreferenceChoices.contentLayouts, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
            }
            .fixedSize()
            .setting("torrent_content_layout")
            Toggle(SettingsCatalog.title("add_to_top_of_queue"), isOn: $model.draft.downloads.addToTopOfQueue)
                .help("The torrent will be added to the top of the download queue")
                .setting("add_to_top_of_queue")
            SpinField(title: SettingsCatalog.key("AddNewTorrentDialog/SavePathHistoryLength"), value: $gui.savePathHistoryLengthValue, range: 0...99)
                .setting("AddNewTorrentDialog/SavePathHistoryLength")
        }

        WatchedFoldersGroup(model: model)

        SettingsGroup(.duplicateTorrents) {
            Toggle(SettingsCatalog.title("merge_trackers"), isOn: $model.draft.downloads.mergeTrackers)
                .setting("merge_trackers")
        } content: {
            Toggle(SettingsCatalog.title("GUI/ConfirmActions/MergeTrackers"), isOn: $gui.confirmMergeTrackers)
                .disabled(!gui.addTorrentDialogEnabled)
                .setting("GUI/ConfirmActions/MergeTrackers")
        }

        TorrentFilesGroup(model: model)
        ExtraTrackersGroup(model: model)
    }

    /// "Start downloads automatically" is the inverse of the stored `add_stopped_enabled`.
    private var startsAutomatically: Binding<Bool> {
        Binding(get: { !model.draft.downloads.addStoppedEnabled }, set: { model.draft.downloads.addStoppedEnabled = !$0 })
    }
}
