import Foundation

/// "Torrent Category Properties" dialog request: new, new subcategory or edit.
struct CategoryEditorRequest: Identifiable {
    enum Mode {
        case new(parent: String?)
        case edit(Category)
    }

    let id = UUID()
    var mode: Mode
    /// Torrents to assign the new category to (context menu "New...").
    var assignTo: [String] = []
}
