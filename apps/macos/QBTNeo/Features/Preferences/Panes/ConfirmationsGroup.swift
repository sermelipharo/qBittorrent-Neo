import SwiftUI

/// General › Confirmations, with the rare ones in "More confirmations".
struct ConfirmationsGroup: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        SettingsGroup(.confirmations) {
            Toggle(SettingsCatalog.title("confirm_torrent_deletion"), isOn: $model.draft.behavior.confirmTorrentDeletion)
                .setting("confirm_torrent_deletion")
        } content: {
            Toggle(SettingsCatalog.title("Preferences/General/ExitConfirm"), isOn: $gui.confirmOnExit)
                .setting("Preferences/General/ExitConfirm")
            Toggle(SettingsCatalog.title("ShutdownConfirmDlg/DontConfirmAutoExit"), isOn: $gui.confirmAutoExit)
                .setting("ShutdownConfirmDlg/DontConfirmAutoExit")
            SettingsDisclosure(title: "More confirmations", section: .confirmations) {
                Toggle(SettingsCatalog.title("confirm_torrent_recheck"), isOn: $model.draft.advanced.confirmTorrentRecheck)
                    .setting("confirm_torrent_recheck")
                Toggle(SettingsCatalog.title("confirm_remove_all_tags"), isOn: $model.draft.advanced.confirmRemoveAllTags)
                    .setting("confirm_remove_all_tags")
                Toggle(
                    SettingsCatalog.title("confirm_remove_tracker_from_all_torrents"),
                    isOn: $model.draft.advanced.confirmRemoveTrackerFromAllTorrents
                )
                .setting("confirm_remove_tracker_from_all_torrents")
                Toggle(SettingsCatalog.title("delete_torrent_content_files"), isOn: $model.draft.behavior.deleteTorrentContentFiles)
                    .setting("delete_torrent_content_files")
            }
        }
    }
}
