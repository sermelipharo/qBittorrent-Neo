import Foundation

/// A single-line text prompt (qBittorrent's `AutoExpandableDialog`).
struct TextPromptRequest: Identifiable {
    enum Purpose {
        case renameTorrent(id: String)
        case renameFile(id: String, path: String, isFolder: Bool)
        case editTracker(id: String, url: String)
        case addWebSeed(id: String)
        case editWebSeed(id: String, url: String)
        case addTags(ids: [String])
    }

    let id = UUID()
    var title: String
    var label: String
    var text: String
    var confirmTitle = String(localized: "OK")
    /// Select only the base name (file renames keep the extension unselected).
    var selectsBaseName = false
    var purpose: Purpose
}
