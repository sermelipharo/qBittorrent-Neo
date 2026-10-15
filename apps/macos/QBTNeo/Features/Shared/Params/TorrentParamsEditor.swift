import SwiftUI

/// The AddTorrentParams editor (features.md §3.2) used by Watched Folder
/// Options and RSS download rules. Every field has a "Default" choice that
/// keeps the global or category setting. Produces two form sections.
struct TorrentParamsEditor: View {
    @Binding var params: TorrentParamsTemplate
    let context: TorrentParamsContext
    @State private var isEditingTags = false

    var body: some View {
        Section("Torrent parameters") {
            Picker("Torrent Management Mode:", selection: $params.autoTmm) {
                Text("Default").tag(Bool?.none)
                Text("Manual").tag(Bool?.some(false))
                Text("Automatic").tag(Bool?.some(true))
            }
            .help("Automatic mode means that various torrent properties (e.g. save path) will be decided by the associated category")

            PathField(
                title: "Save at:", path: $params.savePath, placeholder: suggestedSavePath,
                panelMessage: String(localized: "Choose save path"), validates: false
            )
            .disabled(savePathLocked)
            Picker("Use another path for incomplete torrents:", selection: $params.useDownloadPath) {
                Text("Default").tag(Bool?.none)
                Text("Yes").tag(Bool?.some(true))
                Text("No").tag(Bool?.some(false))
            }
            .disabled(savePathLocked)
            PathField(
                title: "Incomplete torrents:", path: $params.downloadPath,
                placeholder: usesDownloadPath ? context.suggestedDownloadPath(category: params.category) : nil,
                panelMessage: String(localized: "Choose save path"), validates: false
            )
            .disabled(savePathLocked || params.useDownloadPath != true)
            if savePathLocked {
                Text("Note: the current defaults are displayed for reference.")
                    .settingsFootnote()
            }

            Picker("Category:", selection: $params.category) {
                ForEach(categoryChoices, id: \.self) { name in
                    Text(name.isEmpty ? String(localized: "(None)") : name).tag(name)
                }
            }
            LabeledContent("Tags:") {
                HStack {
                    Text(params.tags.isEmpty ? String(localized: "Click [...] button to add/remove tags.") : params.tags.formatted())
                        .foregroundStyle(params.tags.isEmpty ? .secondary : .primary)
                        .lineLimit(2)
                    Button("…") { isEditingTags = true }
                        .help("Add/remove tags")
                        .accessibilityLabel("Add/remove tags")
                }
            }

            Picker("Content layout:", selection: $params.contentLayout) {
                Text("Default").tag(ContentLayout?.none)
                ForEach(PreferenceChoices.contentLayouts, id: \.self) { layout in
                    Text(PreferenceChoices.title(layout)).tag(ContentLayout?.some(layout))
                }
            }
            Picker("Start torrent:", selection: $params.editorStartTorrent) {
                Text("Default").tag(Bool?.none)
                Text("Yes").tag(Bool?.some(true))
                Text("No").tag(Bool?.some(false))
            }
            Picker("Stop condition:", selection: $params.stopCondition) {
                Text("Default").tag(StopCondition?.none)
                ForEach(PreferenceChoices.stopConditions, id: \.self) { condition in
                    Text(PreferenceChoices.title(condition)).tag(StopCondition?.some(condition))
                }
            }
            Picker("Add to top of queue:", selection: $params.addToQueueTop) {
                Text("Default").tag(Bool?.none)
                Text("Yes").tag(Bool?.some(true))
                Text("No").tag(Bool?.some(false))
            }
            Toggle("Skip hash check", isOn: $params.skipChecking)
        }
        .sheet(isPresented: $isEditingTags) {
            TorrentTagsSheet(selected: $params.tags, sessionTags: context.tags)
        }

        ShareLimitsSection(params: $params, fromCategory: !params.category.isEmpty, defaults: inheritedLimits)
    }

    private var effectiveAutomatic: Bool {
        params.autoTmm ?? context.preferences.downloads.autoTmmEnabled
    }

    /// The "Save at" group is read-only for Default and Automatic modes.
    private var savePathLocked: Bool {
        params.autoTmm == nil || effectiveAutomatic
    }

    private var suggestedSavePath: String {
        context.suggestedSavePath(category: params.category, automatic: effectiveAutomatic)
    }

    private var usesDownloadPath: Bool {
        params.useDownloadPath ?? context.usesDownloadPath(category: params.category)
    }

    private var categoryChoices: [String] {
        var names = [""] + context.categoryNames
        if !names.contains(params.category) { names.insert(params.category, at: 1) }
        return names
    }

    private var inheritedLimits: (ratio: Double, seeding: Int64, inactive: Int64) {
        let global = context.preferences.bittorrent
        return (global.maxRatio, global.maxSeedingTime, global.maxInactiveSeedingTime)
    }
}
