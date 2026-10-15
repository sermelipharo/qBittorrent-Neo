import Foundation

/// Sheets of the RSS reader.
enum RSSSheet: Identifiable {
    case newSubscription(url: String)
    case feedOptions(RSSNode)
    case newFolder
    case rename(RSSNode)

    var id: String {
        switch self {
        case .newSubscription: "new"
        case .feedOptions(let node): "options-\(node.id)"
        case .newFolder: "folder"
        case .rename(let node): "rename-\(node.id)"
        }
    }
}
