import SwiftUI

/// qBittorrent's `AddTorrentParamsWidget` (features.md §3.2): every field
/// offers "Default" (use the global/category setting). Used by Watched
/// Folder options and RSS download rules; bind it to a `TorrentParamsTemplate`.
struct TorrentParamsTemplateEditor: View {
    @Binding var params: TorrentParamsTemplate
    /// Category names to offer (sorted).
    let categories: [String]
    @State private var showsTags = false

    var body: some View {
        Picker("Torrent Management Mode:", selection: $params.autoTmm) {
            Text("Default").tag(Bool?.none)
            Text("Manual").tag(Optional(false))
            Text("Automatic").tag(Optional(true))
        }
        LabeledContent("Save at:") {
            PathPicker(title: "Save path", path: $params.savePath, placeholder: String(localized: "Default"))
        }
        .disabled(params.autoTmm != false)
        OptionalBoolPicker(title: "Use another path for incomplete torrents:", value: $params.useDownloadPath)
        LabeledContent("Incomplete path:") {
            PathPicker(title: "Incomplete path", path: $params.downloadPath)
        }
        .disabled(params.useDownloadPath != true)
        Picker("Category:", selection: $params.category) {
            Text("(None)").tag("")
            ForEach(categories, id: \.self) { Text($0).tag($0) }
        }
        LabeledContent("Tags:") {
            HStack {
                Text(params.tags.isEmpty ? String(localized: "None") : params.tags.joined(separator: ", "))
                    .foregroundStyle(params.tags.isEmpty ? .secondary : .primary)
                Button("Edit Tags…") { showsTags = true }
            }
        }
        Picker("Content layout:", selection: $params.contentLayout) {
            Text("Default").tag(ContentLayout?.none)
            Text("Original").tag(Optional(ContentLayout.original))
            Text("Create subfolder").tag(Optional(ContentLayout.subfolder))
            Text("Don't create subfolder").tag(Optional(ContentLayout.noSubfolder))
        }
        Toggle("Skip hash check", isOn: $params.skipChecking)
        Picker("Start torrent:", selection: $params.stopped) {
            Text("Default").tag(Bool?.none)
            Text("Yes").tag(Optional(false))
            Text("No").tag(Optional(true))
        }
        Picker("Stop condition:", selection: $params.stopCondition) {
            Text("Default").tag(StopCondition?.none)
            Text("None").tag(Optional(StopCondition.none))
            Text("Metadata received").tag(Optional(StopCondition.metadataReceived))
            Text("Files checked").tag(Optional(StopCondition.filesChecked))
        }
        OptionalBoolPicker(title: "Add to top of queue:", value: $params.addToQueueTop)
        ShareLimitsEditor(limits: $params.shareLimits)
            .sheet(isPresented: $showsTags) {
                TagsPickerSheet(tags: $params.tags)
            }
    }
}

extension TorrentParamsTemplate {
    /// Share limits as edited by `ShareLimitsEditor` (the template has no action).
    var shareLimits: ShareLimits {
        get { ShareLimits(ratio: ratioLimit, seedingMinutes: seedingTimeLimit, inactiveMinutes: inactiveSeedingTimeLimit) }
        set {
            ratioLimit = newValue.ratio
            seedingTimeLimit = newValue.seedingMinutes
            inactiveSeedingTimeLimit = newValue.inactiveMinutes
        }
    }
}
