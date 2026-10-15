import Foundation

/// Sheets presented on the main window.
enum MainSheet: Identifiable {
    case addLinks(initialText: String)
    case removeTorrents(ids: [String], deleteFiles: Bool)
    case speedLimits
    case torrentOptions(ids: [String])
    case editTrackers(ids: [String])
    case addTrackers(id: String)
    case addPeers(ids: [String])
    case category(CategoryEditorRequest)
    case textPrompt(TextPromptRequest)
    case preview(id: String)
    case lockPassword(lockAfterSaving: Bool)

    var id: String {
        switch self {
        case .addLinks: "addLinks"
        case .removeTorrents(let ids, _): "remove-\(ids.joined())"
        case .speedLimits: "speedLimits"
        case .torrentOptions(let ids): "options-\(ids.joined())"
        case .editTrackers(let ids): "editTrackers-\(ids.joined())"
        case .addTrackers(let id): "addTrackers-\(id)"
        case .addPeers(let ids): "addPeers-\(ids.joined())"
        case .category(let request): "category-\(request.id)"
        case .textPrompt(let request): "prompt-\(request.id)"
        case .preview(let id): "preview-\(id)"
        case .lockPassword: "lockPassword"
        }
    }
}
