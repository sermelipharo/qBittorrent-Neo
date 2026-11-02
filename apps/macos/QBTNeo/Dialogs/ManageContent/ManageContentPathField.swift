import SwiftUI

/// The editable Path cell of the Manage Torrent Content table. Edits reach
/// the model on every keystroke (so Apply and the italics follow at once);
/// Escape puts back the path the edit started from. Edited paths are shown
/// in italics, like qBittorrent's `TorrentContentLayoutItemDelegate`.
struct ManageContentPathField: View {
    let row: ManageContentRow
    let onEdit: (String) -> Void
    @State private var text = ""
    @State private var pathBeforeEditing = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Path", text: $text)
            .labelsHidden()
            .textFieldStyle(.plain)
            .italic(row.isChanged)
            .truncationMode(.middle)
            .focused($isFocused)
            .onAppear { text = row.path }
            .onChange(of: row.path) { _, path in
                if !isFocused { text = path }
            }
            .onChange(of: text) { _, edited in
                if isFocused { onEdit(edited) }
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    pathBeforeEditing = row.path
                } else {
                    text = row.path
                }
            }
            .onSubmit { isFocused = false }
            .onKeyPress(.escape) {
                onEdit(pathBeforeEditing)
                isFocused = false
                text = pathBeforeEditing
                return .handled
            }
    }
}
