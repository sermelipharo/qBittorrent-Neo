import SwiftUI

/// Transfers › Adding › Watched Folders: the folder list with Add…,
/// Options… and Remove (preferences.md §2.2).
struct WatchedFoldersGroup: View {
    @Bindable var model: PreferencesModel
    @Environment(AppModel.self) private var app
    @State private var isPickingFolder = false
    @State private var editing: WatchedFolderEdit?
    @State private var addError: String?

    var body: some View {
        SettingsGroup(.watchedFolders) {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
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
                Button("Add…") { isPickingFolder = true }
            }
            .frame(maxWidth: SettingsLayout.footnoteWidth, alignment: .leading)
            .setting("scan_dirs")
        } content: {
            EmptyView()
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
        guard let path = AppDefaults.store.string(forKey: FeatureDefaults.watchedFolderLastPath) else { return nil }
        return URL(filePath: path).deletingLastPathComponent()
    }

    private func folderPicked(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        let path = url.path(percentEncoded: false)
        if let error = WatchedFolderValidator.error(for: path, existing: model.draft.downloads.watchedFolders.map(\.path)) {
            addError = error
            return
        }
        AppDefaults.store.set(path, forKey: FeatureDefaults.watchedFolderLastPath)
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
