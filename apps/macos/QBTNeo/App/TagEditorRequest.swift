import Foundation

/// Tag dialog request: a new tag, or the icon and color of an existing one
/// (qBittorrent tags cannot be renamed).
struct TagEditorRequest: Identifiable {
    enum Mode {
        case new
        case edit(String)
    }

    let id = UUID()
    var mode: Mode
}
