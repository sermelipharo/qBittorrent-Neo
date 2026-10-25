import SwiftUI

/// Left pane of the Add Torrent dialog: where it goes, its category and
/// tags, and whether it starts, with the rarer options under "More options".
struct AddTorrentOptionsForm: View {
    @Bindable var dialog: AddTorrentModel
    @Environment(GUIPreferences.self) private var gui
    @State private var showsTags = false

    var body: some View {
        @Bindable var gui = gui
        Form {
            Section {
                LabeledContent("Save to") {
                    FolderMenu(title: "Save path", path: $dialog.savePath, history: dialog.savePathHistory)
                        .fixedSize()
                }
                .disabled(dialog.autoTMM)
                .help(dialog.autoTMM ? String(localized: "The category decides the save path in automatic mode") : dialog.savePath)
                Picker("Category", selection: $dialog.category) {
                    ForEach(dialog.categoryChoices, id: \.self) { name in
                        Text(name.isEmpty ? String(localized: "(None)") : name).tag(name)
                    }
                }
                LabeledContent("Tags") {
                    HStack(spacing: Design.Spacing.tight) {
                        Text(dialog.tags.isEmpty ? String(localized: "None") : dialog.tags.joined(separator: ", "))
                            .foregroundStyle(dialog.tags.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Button("Edit Tags…", systemImage: Symbol.plus) { showsTags = true }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .help("Add/remove tags")
                    }
                }
            }
            Section {
                Toggle("Start torrent", isOn: $dialog.startTorrent)
                Toggle("Download in sequential order", isOn: $dialog.sequential)
            }
            Section {
                DisclosureGroup(isExpanded: $gui.addTorrentMoreOptions) {
                    moreOptions
                } label: {
                    HStack(spacing: Design.Spacing.small) {
                        Text("More options")
                        if !gui.addTorrentMoreOptions {
                            Text(dialog.moreOptionsSummary)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showsTags) {
            TagsPickerSheet(tags: $dialog.tags)
        }
    }

    @ViewBuilder private var moreOptions: some View {
        Picker("Management", selection: $dialog.autoTMM) {
            Text("Manual").tag(false)
            Text("Automatic").tag(true)
        }
        .help("Automatic mode means that various torrent properties (e.g. save path) will be decided by the associated category")
        Toggle("Use another path for incomplete torrent", isOn: $dialog.useDownloadPath)
            .disabled(dialog.autoTMM)
        if dialog.useDownloadPath, !dialog.autoTMM {
            LabeledContent("Incomplete path") {
                FolderMenu(title: "Incomplete path", path: $dialog.downloadPath, history: dialog.downloadPathHistory)
                    .fixedSize()
            }
        }
        Toggle("Remember last used save path", isOn: $dialog.rememberLastSavePath)
        Toggle("Set as default category", isOn: $dialog.setAsDefaultCategory)
        Picker("Stop condition", selection: $dialog.stopCondition) {
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
        Toggle("Download first and last pieces first", isOn: $dialog.firstLastPiece)
        Picker("Content layout", selection: $dialog.contentLayout) {
            Text("Original").tag(ContentLayout.original)
            Text("Create subfolder").tag(ContentLayout.subfolder)
            Text("Don't create subfolder").tag(ContentLayout.noSubfolder)
        }
    }
}
