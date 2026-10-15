import SwiftUI

/// "Preview selection" (features.md §2.9): previewable media files of a
/// torrent, opened with the default application.
struct PreviewSheet: View {
    let id: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var files: [TorrentFile] = []
    @State private var selection: Int64?
    @State private var loaded = false

    var body: some View {
        let name = model.transfers.item(id)?.name ?? ""
        DialogContainer(title: "Preview selection", confirmTitle: "Preview", isConfirmDisabled: selection == nil,
                        width: Design.Window.wideDialogWidth, onConfirm: preview) {
            Text("The following files from torrent \"\(name)\" support previewing, please select one of them:")
                .fixedSize(horizontal: false, vertical: true)
            Table(files, selection: $selection) {
                TableColumn("Name") { file in Text((file.name as NSString).lastPathComponent) }
                TableColumn("Size") { file in Text(UnitFormatter.size(file.size)).monospacedDigit() }
                    .width(90)
                TableColumn("Progress") { file in ProgressBarView(progress: file.progress) }
                    .width(110)
            }
            .frame(height: 200)
            .overlay {
                if loaded, files.isEmpty {
                    ContentUnavailableView("Unable to preview", systemImage: Symbol.eyeSlash,
                                           description: Text("The selected torrent \"\(name)\" does not contain previewable files"))
                }
            }
        }
        .task {
            files = await model.previewableFiles(id)
            selection = files.first?.index
            loaded = true
        }
    }

    private func preview() {
        guard let file = files.first(where: { $0.index == selection }) else { return }
        model.openPreview(id, file: file)
        dismiss()
    }
}

extension TorrentFile: Identifiable {
    public var id: Int64 { index }
}
