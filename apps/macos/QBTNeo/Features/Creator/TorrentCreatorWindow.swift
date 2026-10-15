import AppKit
import SwiftUI

/// Tools › Torrent Creator (features.md §3.5).
struct TorrentCreatorWindow: View {
    @Environment(AppModel.self) private var app
    @State private var model = TorrentCreatorModel()
    @State private var isPickingFile = false
    @State private var isPickingFolder = false

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            Form {
                Section("Select file/folder to share") {
                    LabeledContent("Path:") {
                        Text(model.sourcePath)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                    HStack {
                        Text("Drag and drop a file or folder here")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Select file") { isPickingFile = true }
                        Button("Select folder") { isPickingFolder = true }
                    }
                }
                Section("Settings") {
                    Picker("Torrent format:", selection: $model.format) {
                        ForEach(TorrentCreatorModel.formats, id: \.self) { format in
                            Text(Self.title(format)).tag(format)
                        }
                    }
                    Picker("Piece size:", selection: $model.pieceSize) {
                        ForEach(TorrentCreatorModel.pieceSizes, id: \.self) { size in
                            Text(TorrentCreatorModel.pieceSizeTitle(size)).tag(size)
                        }
                    }
                    LabeledContent("Number of pieces:") {
                        HStack {
                            if model.isCounting {
                                Text("Calculating...").foregroundStyle(.secondary)
                            } else if let count = model.pieceCount {
                                Text(count.formatted()).monospacedDigit()
                            }
                            Button("Calculate number of pieces") { Task { await model.calculatePieces() } }
                                .disabled(model.isCounting)
                        }
                    }
                    Toggle("Private torrent (Won't distribute on DHT network)", isOn: $model.isPrivate)
                    Toggle("Start seeding immediately", isOn: $model.startSeeding)
                    Toggle("Ignore share ratio limits for this torrent", isOn: $model.ignoreShareLimits)
                        .disabled(!model.startSeeding)
                        .padding(.leading, Design.Spacing.xLarge)
                    Toggle("Optimize alignment", isOn: $model.optimizeAlignment)
                        .disabled(model.format != .v1)
                        .help("v2 and hybrid torrents are always aligned to piece boundaries")
                    SpinField(title: "Align to piece boundary for files larger than:", value: $model.paddingLimitKiB,
                              range: -1...Int64(Int32.max), unit: UnitFormatter.kib, special: .text(String(localized: "Disabled"), at: -1),
                              width: FeatureDesign.Width.wideSpinField)
                        .disabled(model.format != .v1 || !model.optimizeAlignment)
                }
                Section("Fields") {
                    LabeledContent("Tracker URLs:") {
                        CommitTextEditor(title: "Tracker URLs:", text: $model.trackers, minHeight: 80,
                                         prompt: String(localized: "You can separate tracker tiers / groups with an empty line."))
                    }
                    LabeledContent("Web seed URLs:") {
                        CommitTextEditor(title: "Web seed URLs:", text: $model.webSeeds, minHeight: 56)
                    }
                    LabeledContent("Comments:") {
                        CommitTextEditor(title: "Comments:", text: $model.comment, minHeight: 56)
                    }
                    CommitTextField(title: "Source:", text: $model.source)
                }
            }
            .formStyle(.grouped)
            .disabled(model.isCreating)
            HStack(spacing: Design.Spacing.medium) {
                Text("Progress:")
                ProgressView(value: model.progress)
                    .accessibilityLabel("Progress")
                if model.isCreating {
                    Button("Cancel", role: .cancel, action: model.cancel)
                } else {
                    Button("Create Torrent", action: chooseDestination)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(Design.Spacing.medium)
            .background(.bar)
        }
        .frame(minWidth: FeatureDesign.Window.creatorMin.width, minHeight: FeatureDesign.Window.creatorMin.height)
        .navigationTitle(AppWindowID.creator.title)
        .dropDestination(for: URL.self) { urls, _ in
            guard let url = urls.first, url.isFileURL else { return false }
            model.sourcePath = url.path(percentEncoded: false)
            return true
        }
        .fileImporter(isPresented: $isPickingFile, allowedContentTypes: [.item]) { pick($0) }
        .fileDialogMessage(Text("Select file"))
        .fileImporter(isPresented: $isPickingFolder, allowedContentTypes: [.folder]) { pick($0) }
        .alert(model.alert?.title ?? "", item: $model.alert) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
        .task(id: app.phase) { model.attach(app.client) }
    }

    private static func title(_ format: TorrentFormat) -> String {
        switch format {
        case .v1: "V1"
        case .v2: "V2"
        case .hybrid: String(localized: "Hybrid")
        }
    }

    private func pick(_ result: Result<URL, any Error>) {
        if case .success(let url) = result { model.sourcePath = url.path(percentEncoded: false) }
    }

    /// "Select where to save the new torrent" (a save panel is the only way
    /// to get a destination path without writing a file first).
    private func chooseDestination() {
        let panel = NSSavePanel()
        panel.title = String(localized: "Select where to save the new torrent")
        panel.allowedContentTypes = [.torrent]
        panel.nameFieldStringValue = model.defaultTorrentName
        if let last = AppDefaults.store.string(forKey: FeatureDefaults.creatorLastSavePath) {
            panel.directoryURL = URL(filePath: last)
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        model.create(savingTo: url)
    }
}
