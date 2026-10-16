import SwiftUI

/// "Torrent Category Properties" (features.md §3.21): name, save path and
/// the incomplete-download path option, plus the category's icon and color
/// (GUI-only, kept in `LabelAppearanceStore`).
struct CategoryEditorSheet: View {
    let request: CategoryEditorRequest
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var savePath = ""
    @State private var downloadMode = 0
    @State private var downloadPath = ""
    @State private var shareLimits = ShareLimits()
    @State private var appearance = LabelAppearance()
    @State private var error: String?

    var body: some View {
        DialogContainer(title: "Torrent Category Properties", isConfirmDisabled: name.trimmingCharacters(in: .whitespaces).isEmpty,
                        width: Design.Window.wideDialogWidth, onConfirm: save) {
            Form {
                TextField("Name:", text: $name)
                    .disabled(isEditing)
                LabelAppearanceFields(kind: .category, appearance: $appearance)
                LabeledContent("Save path:") {
                    PathPicker(title: "Save path", path: $savePath, placeholder: defaultSavePath)
                }
                Picker("Use another path for incomplete torrents:", selection: $downloadMode) {
                    Text("Default").tag(0)
                    Text("Yes").tag(1)
                    Text("No").tag(2)
                }
                LabeledContent("Path:") {
                    PathPicker(title: "Download path", path: $downloadPath)
                }
                .disabled(downloadMode != 1)
                Section("Torrent share limits") {
                    ShareLimitsEditor(limits: $shareLimits, fromCategory: name.contains("/"))
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .fixedSize(horizontal: false, vertical: true)
            if let error {
                Label(error, systemImage: Symbol.exclamationmarkTriangleFill)
                    .foregroundStyle(TorrentState.error.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear(perform: load)
    }

    private var isEditing: Bool {
        if case .edit = request.mode { return true }
        return false
    }

    private var defaultSavePath: String {
        let base = model.corePreferences.downloads.savePath
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? base : base + "/" + trimmed
    }

    private func load() {
        switch request.mode {
        case .new(let parent):
            name = parent.map { $0 + "/" } ?? ""
            name += String(localized: "New Category")
        case .edit(let category):
            name = category.name
            appearance = model.labels.ownCategory(category.name)
            savePath = category.savePath
            shareLimits = category.shareLimits
            switch category.downloadPath {
            case .default: downloadMode = 0
            case .path(let path):
                downloadMode = 1
                downloadPath = path
            case .disabled: downloadMode = 2
            }
        }
    }

    private func save() {
        let option: CategoryDownloadPath = switch downloadMode {
        case 1: .path(path: downloadPath)
        case 2: .disabled
        default: .default
        }
        if let message = model.saveCategory(request, name: name.trimmingCharacters(in: .whitespaces), savePath: savePath,
                                            downloadPath: option, shareLimits: shareLimits, appearance: appearance) {
            error = message
        } else {
            dismiss()
        }
    }
}
