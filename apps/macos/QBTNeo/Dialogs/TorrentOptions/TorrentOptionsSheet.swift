import SwiftUI

/// "Torrent Options" (features.md §3.10) for one or many torrents.
struct TorrentOptionsSheet: View {
    let ids: [String]
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var state = TorrentOptionsState()
    @State private var original = TorrentOptionsState()

    var body: some View {
        let automatic = TorrentOptionsState.uniform(state.autoTMM)
        DialogContainer(title: "Torrent Options", width: 600, onConfirm: save) {
            Form {
                Section {
                    TriStateToggle(title: "Automatic Torrent Management", values: $state.autoTMM)
                        .help("Automatic mode means that various torrent properties (e.g. save path) will be decided by the associated category")
                    LabeledContent("Save at:") {
                        PathPicker(title: "Save path", path: $state.savePath)
                    }
                    .disabled(automatic != false)
                    TriStateToggle(title: "Use another path for incomplete torrent", values: $state.useDownloadPath)
                        .disabled(automatic != false)
                    LabeledContent("Incomplete path:") {
                        PathPicker(title: "Incomplete path", path: $state.downloadPath)
                    }
                    .disabled(automatic != false || TorrentOptionsState.uniform(state.useDownloadPath) != true)
                    Picker("Category:", selection: $state.category) {
                        if original.category == nil {
                            Text("--Currently used categories--").tag(String?.none)
                        }
                        Text("(None)").tag(Optional(""))
                        ForEach(model.categories.sortedNames, id: \.self) { name in
                            Text(name).tag(Optional(name))
                        }
                    }
                }
                Section("Torrent Speed Limits") {
                    SpeedLimitField(title: "Upload:", limit: $state.uploadLimit, showsSlider: true)
                    SpeedLimitField(title: "Download:", limit: $state.downloadLimit, showsSlider: true)
                    Text("These will not exceed the global limits")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Section("Torrent Share Limits") {
                    ShareLimitsEditor(limits: $state.shareLimits)
                }
                Section {
                    TriStateToggle(title: "Download in sequential order", values: $state.sequential)
                    TriStateToggle(title: "Download first and last pieces first", values: $state.firstLast)
                }
                Section {
                    TriStateToggle(title: "Disable DHT for this torrent", values: $state.disableDHT)
                    TriStateToggle(title: "Disable PeX for this torrent", values: $state.disablePeX)
                    TriStateToggle(title: "Disable LSD for this torrent", values: $state.disableLSD)
                }
                .disabled(state.allPrivate || state.disableDHT.isEmpty)
                .help("Not applicable to private torrents")
            }
            .formStyle(.grouped)
            .frame(height: 560)
        }
        .onAppear {
            state = TorrentOptionsState(items: model.items(ids), discovery: model.discoveryOptions(ids))
            original = state
        }
    }

    /// Applies only the fields the user changed.
    private func save() {
        let new = state
        let old = original
        let ids = ids
        model.performAsync { client in
            if new.autoTMM != old.autoTMM, let value = TorrentOptionsState.uniform(new.autoTMM) {
                try client.setAutoManagement(hashes: ids, enabled: value)
            }
            if TorrentOptionsState.uniform(new.autoTMM) == false {
                if new.savePath != old.savePath, !new.savePath.isEmpty { try await client.setSavePath(hashes: ids, path: new.savePath) }
                if new.useDownloadPath != old.useDownloadPath || new.downloadPath != old.downloadPath {
                    let use = TorrentOptionsState.uniform(new.useDownloadPath) ?? true
                    try await client.setDownloadPath(hashes: ids, path: use ? new.downloadPath : "")
                }
            }
            if new.category != old.category, let category = new.category {
                try client.setCategory(hashes: ids, category: category)
            }
            if new.downloadLimit != old.downloadLimit, new.downloadLimit >= 0 {
                try client.setDownloadLimit(hashes: ids, limit: new.downloadLimit)
            }
            if new.uploadLimit != old.uploadLimit, new.uploadLimit >= 0 {
                try client.setUploadLimit(hashes: ids, limit: new.uploadLimit)
            }
            if new.shareLimits != old.shareLimits {
                let limits = new.shareLimits
                try client.setShareLimits(hashes: ids, ratioLimit: limits.ratio, seedingTimeLimit: limits.seedingMinutes,
                                          inactiveSeedingTimeLimit: limits.inactiveMinutes, action: limits.action)
            }
            if new.sequential != old.sequential, let value = TorrentOptionsState.uniform(new.sequential) {
                try client.setSequentialDownload(hashes: ids, value: value)
            }
            if new.firstLast != old.firstLast, let value = TorrentOptionsState.uniform(new.firstLast) {
                try client.setFirstLastPiecePriority(hashes: ids, value: value)
            }
            if new.disableDHT != old.disableDHT, let value = TorrentOptionsState.uniform(new.disableDHT) {
                try client.setDhtDisabled(hashes: ids, value: value)
            }
            if new.disablePeX != old.disablePeX, let value = TorrentOptionsState.uniform(new.disablePeX) {
                try client.setPexDisabled(hashes: ids, value: value)
            }
            if new.disableLSD != old.disableLSD, let value = TorrentOptionsState.uniform(new.disableLSD) {
                try client.setLsdDisabled(hashes: ids, value: value)
            }
        }
        dismiss()
    }
}
