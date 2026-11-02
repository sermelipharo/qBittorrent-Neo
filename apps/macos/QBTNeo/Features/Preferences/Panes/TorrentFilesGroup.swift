import SwiftUI

/// Transfers › Adding › .torrent Files (advanced): deleting them after adding
/// and keeping backups ("Store backup .torrent file").
struct TorrentFilesGroup: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        SettingsGroup(.torrentFiles) {
            VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                Toggle(SettingsCatalog.title("auto_delete_mode"), isOn: $model.deletesTorrentFiles)
                    .help("Whether the .torrent file should be deleted after adding it")
                Toggle("Also when addition is cancelled", isOn: $model.deletesCancelledTorrentFiles)
                    .help("Also delete .torrent files whose addition was cancelled")
                    .disabled(!model.deletesTorrentFiles)
                    .padding(.leading, SettingsLayout.indent)
                if model.deletesTorrentFiles {
                    InlineMessage(text: String(localized: "Warning! Data loss possible!"), style: .warning)
                        .help("Files opened through file association are deleted as well.")
                }
            }
            .setting("auto_delete_mode")
        } content: {
            backupRow("torrent_files_backup_enabled", isOn: $model.draft.downloads.torrentFilesBackupEnabled,
                      path: $model.draft.downloads.torrentFilesBackupDir)
            backupRow("torrent_files_finished_backup_dir_enabled", isOn: $model.draft.downloads.torrentFilesFinishedBackupDirEnabled,
                      path: $model.draft.downloads.torrentFilesFinishedBackupDir)
            Toggle(SettingsCatalog.title("remove_torrent_file_backup"), isOn: $model.draft.downloads.removeTorrentFileBackup)
                .setting("remove_torrent_file_backup")
        }
    }

    /// A relative folder is inside the profile's data folder and is created
    /// when needed, so it isn't validated.
    private func backupRow(_ id: String, isOn: Binding<Bool>, path: Binding<String>) -> some View {
        LabeledContent {
            HStack(spacing: Design.Spacing.small) {
                Toggle(SettingsCatalog.title(id), isOn: isOn)
                    .labelsHidden()
                PathControl(title: SettingsCatalog.key(id), path: path, placeholder: "backup",
                            panelMessage: String(localized: "Choose backup directory"), validates: false)
                    .disabled(!isOn.wrappedValue)
            }
        } label: {
            Text(SettingsCatalog.title(id))
        }
        .setting(id)
    }
}
