import SwiftUI

/// Transfers › Adding › .torrent Files (advanced): deleting them after adding
/// and copying them to export folders.
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
            exportRow("export_dir", isOn: $model.exportDirectoryEnabled, path: $model.draft.downloads.exportDir)
            exportRow("export_dir_fin", isOn: $model.finishedExportDirectoryEnabled, path: $model.draft.downloads.exportDirFin)
        }
    }

    private func exportRow(_ id: String, isOn: Binding<Bool>, path: Binding<String>) -> some View {
        LabeledContent {
            HStack(spacing: Design.Spacing.small) {
                Toggle(SettingsCatalog.title(id), isOn: isOn)
                    .labelsHidden()
                PathControl(title: SettingsCatalog.key(id), path: path, panelMessage: String(localized: "Choose export directory"))
                    .disabled(!isOn.wrappedValue)
            }
        } label: {
            Text(SettingsCatalog.title(id))
        }
        .setting(id)
    }
}
