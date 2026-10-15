import SwiftUI

/// "Watched Folder Options" (features.md §3.20): recursive mode and the
/// parameters applied to torrents added from the folder.
struct WatchedFolderSheet: View {
    @State private var edit: WatchedFolderEdit
    let context: TorrentParamsContext
    let save: (WatchedFolderEdit) -> Void
    @Environment(\.dismiss) private var dismiss

    init(edit: WatchedFolderEdit, context: TorrentParamsContext, save: @escaping (WatchedFolderEdit) -> Void) {
        _edit = State(initialValue: edit)
        self.context = context
        self.save = save
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    LabeledContent("Watched folder:") {
                        Text(edit.folder.path)
                            .lineLimit(2)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                    }
                    Toggle("Recursive mode", isOn: $edit.folder.recursive)
                        .help("""
                            Will watch the folder and all its subfolders. In Manual torrent management mode it will \
                            also add subfolder name to the selected Save path.
                            """)
                }
                TorrentParamsEditor(params: $edit.folder.params, context: context)
            }
            .formStyle(.grouped)
            SheetButtons(confirmTitle: "OK", confirm: confirm)
        }
        .frame(width: FeatureDesign.Window.wideSheetWidth, height: 640)
        .navigationTitle("Watched Folder Options")
    }

    private func confirm() {
        save(edit)
        dismiss()
    }
}
