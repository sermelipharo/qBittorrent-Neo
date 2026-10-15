import SwiftUI

/// Left pane of the Add Torrent dialog: management mode, paths, category,
/// tags and torrent options.
struct AddTorrentOptionsForm: View {
    @Bindable var dialog: AddTorrentModel
    @State private var showsTags = false

    var body: some View {
        Form {
            Section {
                Picker("Torrent Management Mode:", selection: $dialog.autoTMM) {
                    Text("Manual").tag(false)
                    Text("Automatic").tag(true)
                }
                .help("Automatic mode means that various torrent properties (e.g. save path) will be decided by the associated category")
            }
            Section("Save at") {
                PathPicker(title: "Save path", path: $dialog.savePath, history: dialog.savePathHistory)
                    .disabled(dialog.autoTMM)
                Toggle("Use another path for incomplete torrent", isOn: $dialog.useDownloadPath)
                    .disabled(dialog.autoTMM)
                PathPicker(title: "Incomplete path", path: $dialog.downloadPath, history: dialog.downloadPathHistory)
                    .disabled(dialog.autoTMM || !dialog.useDownloadPath)
                Toggle("Remember last used save path", isOn: $dialog.rememberLastSavePath)
            }
            Section("Torrent options") {
                Picker("Category:", selection: $dialog.category) {
                    ForEach(dialog.categoryChoices, id: \.self) { name in
                        Text(name.isEmpty ? String(localized: "(None)") : name).tag(name)
                    }
                }
                Toggle("Set as default category", isOn: $dialog.setAsDefaultCategory)
                LabeledContent("Tags:") {
                    HStack {
                        Text(dialog.tags.isEmpty ? String(localized: "None") : dialog.tags.joined(separator: ", "))
                            .foregroundStyle(dialog.tags.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                        Button("Edit Tags…") { showsTags = true }
                            .help("Add/remove tags")
                    }
                }
                Toggle("Start torrent", isOn: $dialog.startTorrent)
                Picker("Stop condition:", selection: $dialog.stopCondition) {
                    Text("None").tag(StopCondition.none)
                    if !dialog.hasMetadata {
                        Text("Metadata received").tag(StopCondition.metadataReceived)
                    }
                    Text("Files checked").tag(StopCondition.filesChecked)
                }
                .disabled(!dialog.startTorrent)
                .help("""
                    None: no stop condition is set. Metadata received: the torrent will stop after metadata is received. \
                    Files checked: the torrent will stop after files are initially checked.
                    """)
                Toggle("Add to top of queue", isOn: $dialog.addToQueueTop)
                Toggle("Skip hash check", isOn: $dialog.skipHashCheck)
                Toggle("Download in sequential order", isOn: $dialog.sequential)
                Toggle("Download first and last pieces first", isOn: $dialog.firstLastPiece)
                Picker("Content layout:", selection: $dialog.contentLayout) {
                    Text("Original").tag(ContentLayout.original)
                    Text("Create subfolder").tag(ContentLayout.subfolder)
                    Text("Don't create subfolder").tag(ContentLayout.noSubfolder)
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showsTags) {
            TagsPickerSheet(tags: $dialog.tags)
        }
    }
}
