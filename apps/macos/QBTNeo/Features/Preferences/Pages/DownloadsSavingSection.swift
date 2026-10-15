import SwiftUI

/// Downloads › Saving Management.
struct DownloadsSavingSection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Section("Saving Management") {
            Picker("Default Torrent Management Mode:", selection: $model.draft.downloads.autoTmmEnabled) {
                Text("Manual").tag(false)
                Text("Automatic").tag(true)
            }.settingAnchor("downloads.28")
            .help("""
                Automatic: Various torrent properties (e.g. save path) will be decided by the associated category
                Manual: Various torrent properties (e.g. save path) must be assigned manually
                """)
            Picker("When Torrent Category changed:", selection: $model.draft.downloads.torrentChangedTmmEnabled) {
                Text("Relocate torrent").tag(true)
                Text("Switch torrent to Manual Mode").tag(false)
            }.settingAnchor("downloads.29")
            Picker("When Default Save/Incomplete Path changed:", selection: $model.draft.downloads.savePathChangedTmmEnabled) {
                Text("Relocate affected torrents").tag(true)
                Text("Switch affected torrents to Manual Mode").tag(false)
            }.settingAnchor("downloads.30")
            Picker("When Category Save Path changed:", selection: $model.draft.downloads.categoryChangedTmmEnabled) {
                Text("Relocate affected torrents").tag(true)
                Text("Switch affected torrents to Manual Mode").tag(false)
            }.settingAnchor("downloads.31")
            Toggle("Use Category paths in Manual Mode", isOn: $model.draft.downloads.useCategoryPathsInManualMode).settingAnchor("downloads.32")
                .help("Resolve relative Save Path against appropriate Category path instead of Default one")
            PathField(
                title: "Default Save Path:", path: $model.draft.downloads.savePath,
                panelMessage: String(localized: "Choose a save directory")
            )
            LabeledContent {
                PathControl(
                    title: "Use another path for incomplete torrents:", path: $model.draft.downloads.tempPath,
                    placeholder: model.draft.downloads.savePath + "/temp", panelMessage: String(localized: "Choose a save directory")
                )
                .disabled(!model.draft.downloads.tempPathEnabled)
            } label: {
                Toggle("Use another path for incomplete torrents:", isOn: $model.draft.downloads.tempPathEnabled).settingAnchor("downloads.33")
            }
            LabeledContent {
                PathControl(
                    title: "Copy .torrent files to:", path: $model.draft.downloads.exportDir,
                    panelMessage: String(localized: "Choose export directory")
                )
                .disabled(!model.exportDirectoryEnabled)
            } label: {
                Toggle("Copy .torrent files to:", isOn: $model.exportDirectoryEnabled).settingAnchor("downloads.34")
            }
            LabeledContent {
                PathControl(
                    title: "Copy .torrent files for finished downloads to:", path: $model.draft.downloads.exportDirFin,
                    panelMessage: String(localized: "Choose export directory")
                )
                .disabled(!model.finishedExportDirectoryEnabled)
            } label: {
                Toggle("Copy .torrent files for finished downloads to:", isOn: $model.finishedExportDirectoryEnabled).settingAnchor("downloads.35")
            }
        }.settingAnchor("downloads.27")
    }
}
