import SwiftUI

/// Downloads › "Automatically add torrents from:" — watched folders with
/// Add…, Options… and Remove (preferences.md §2.2).
struct WatchedFoldersSection: View {
    @Bindable var model: PreferencesModel
    @Environment(AppModel.self) private var app
    @State private var isPickingFolder = false
    @State private var editing: WatchedFolderEdit?
    @State private var addError: String?

    var body: some View {
        Section {
            if model.draft.downloads.watchedFolders.isEmpty {
                Text("No watched folders")
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(model.draft.downloads.watchedFolders.enumerated()), id: \.element.path) { index, folder in
                WatchedFolderRow(folder: folder) {
                    editing = WatchedFolderEdit(index: index, folder: folder)
                } remove: {
                    model.draft.downloads.watchedFolders.removeAll { $0.path == folder.path }
                }
            }
            HStack {
                Spacer()
                Button("Add…") { isPickingFolder = true }
            }
        } header: {
            Text("Automatically add torrents from:")
        }
        .fileImporter(isPresented: $isPickingFolder, allowedContentTypes: [.folder], onCompletion: folderPicked)
        .fileDialogMessage(Text("Select folder to monitor"))
        .fileDialogDefaultDirectory(lastDirectory)
        .sheet(item: $editing) { edit in
            WatchedFolderSheet(edit: edit, context: TorrentParamsContext(app: app), save: save)
        }
        .alert("Adding entry failed", item: $addError) { _ in
            Button("OK") {}
        } message: { error in
            Text(error)
        }
    }

    private var lastDirectory: URL? {
        guard let path = UserDefaults.standard.string(forKey: FeatureDefaults.watchedFolderLastPath) else { return nil }
        return URL(filePath: path).deletingLastPathComponent()
    }

    private func folderPicked(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        let path = url.path(percentEncoded: false)
        if let error = WatchedFolderValidator.error(for: path, existing: model.draft.downloads.watchedFolders.map(\.path)) {
            addError = error
            return
        }
        UserDefaults.standard.set(path, forKey: FeatureDefaults.watchedFolderLastPath)
        editing = WatchedFolderEdit(index: nil, folder: WatchedFolder(path: path, recursive: false, params: .defaults))
    }

    private func save(_ edit: WatchedFolderEdit) {
        if let index = edit.index, model.draft.downloads.watchedFolders.indices.contains(index) {
            model.draft.downloads.watchedFolders[index] = edit.folder
        } else {
            model.draft.downloads.watchedFolders.append(edit.folder)
        }
    }
}
