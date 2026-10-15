import SwiftUI

/// Transfers › Files: removing torrents, files on disk, categories and
/// automatic mode, and running a program.
struct TransfersFilesSegment: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        SettingsGroup(.removingTorrents) {
            Picker(SettingsCatalog.title("torrent_content_remove_option"), selection: $model.draft.advanced.torrentContentRemoveOption) {
                ForEach(AdvancedChoices.removeOptions, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .pickerStyle(.radioGroup)
            .setting("torrent_content_remove_option")
        }

        SettingsGroup(.filesOnDisk) {
            Toggle(SettingsCatalog.title("preallocate_all"), isOn: $model.draft.downloads.preallocateAll)
                .help("Allocate full file sizes on disk before starting downloads, to minimize fragmentation. Only useful for HDDs.")
                .setting("preallocate_all")
        } content: {
            Toggle(SettingsCatalog.title("incomplete_files_ext"), isOn: $model.draft.downloads.incompleteFilesExt)
                .setting("incomplete_files_ext")
            Toggle(SettingsCatalog.title("use_unwanted_folder"), isOn: $model.draft.downloads.useUnwantedFolder)
                .setting("use_unwanted_folder")
            Toggle(SettingsCatalog.title("recheck_completed_torrents"), isOn: $model.draft.advanced.recheckCompletedTorrents)
                .setting("recheck_completed_torrents")
            Toggle(SettingsCatalog.title("Preferences/Advanced/DisableRecursiveDownload"), isOn: $gui.recursiveDownloadEnabled)
                .setting("Preferences/Advanced/DisableRecursiveDownload")
            Toggle(SettingsCatalog.title("excluded_file_names_enabled"), isOn: $model.draft.downloads.excludedFileNamesEnabled)
                .setting("excluded_file_names_enabled")
            DisclosureGroup("Edit excluded file names") {
                VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                    CommitTextEditor(title: SettingsCatalog.key("excluded_file_names_enabled"), text: $model.excludedFileNamesText,
                                     prompt: "*.exe\nreadme[0-9].txt")
                        .labelsHidden()
                    SettingFootnote(text: ExcludedFileNamesHelp.text)
                }
            }
            .disabled(!model.draft.downloads.excludedFileNamesEnabled)
            .padding(.leading, SettingsLayout.indent)
        }

        SettingsGroup(.categories) {
            Picker(SettingsCatalog.title("auto_tmm_enabled"), selection: $model.draft.downloads.autoTmmEnabled) {
                Text("Manual").tag(false)
                Text("Automatic").tag(true)
            }
            .fixedSize()
            .setting("auto_tmm_enabled")
            Picker(SettingsCatalog.title("torrent_changed_tmm_enabled"), selection: $model.draft.downloads.torrentChangedTmmEnabled) {
                Text("Relocate torrent").tag(true)
                Text("Switch torrent to Manual Mode").tag(false)
            }
            .fixedSize()
            .setting("torrent_changed_tmm_enabled")
            Picker(SettingsCatalog.title("save_path_changed_tmm_enabled"), selection: $model.draft.downloads.savePathChangedTmmEnabled) {
                Text("Relocate affected torrents").tag(true)
                Text("Switch affected torrents to Manual Mode").tag(false)
            }
            .fixedSize()
            .setting("save_path_changed_tmm_enabled")
            Picker(SettingsCatalog.title("category_changed_tmm_enabled"), selection: $model.draft.downloads.categoryChangedTmmEnabled) {
                Text("Relocate affected torrents").tag(true)
                Text("Switch affected torrents to Manual Mode").tag(false)
            }
            .fixedSize()
            .setting("category_changed_tmm_enabled")
            Toggle(SettingsCatalog.title("use_category_paths_in_manual_mode"), isOn: $model.draft.downloads.useCategoryPathsInManualMode)
                .help("Resolve relative Save Path against appropriate Category path instead of Default one")
                .setting("use_category_paths_in_manual_mode")
        }

        RunProgramGroup(model: model)
    }
}
