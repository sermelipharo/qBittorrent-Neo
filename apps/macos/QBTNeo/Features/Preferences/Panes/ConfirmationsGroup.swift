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
                Toggle(SettingsCatalog.title("Preferences/Advanced/confirmRemoveAllTags"), isOn: $gui.confirmRemoveAllTags)
                    .setting("Preferences/Advanced/confirmRemoveAllTags")
                Toggle(SettingsCatalog.title("GUI/ConfirmActions/RemoveTrackerFromAllTorrents"), isOn: $gui.confirmRemoveTrackerFromAllTorrents)
                    .setting("GUI/ConfirmActions/RemoveTrackerFromAllTorrents")
                Toggle(SettingsCatalog.title("delete_torrent_content_files"), isOn: $model.draft.behavior.deleteTorrentContentFiles)
                    .setting("delete_torrent_content_files")
            }
        }
    }
}
