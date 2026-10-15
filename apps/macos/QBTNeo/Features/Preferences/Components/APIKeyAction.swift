import Foundation

/// The confirmed API key operations of the WebUI page.
enum APIKeyAction: Hashable {
    case generate
    case rotate
    case delete

    var title: String {
        switch self {
        case .generate: String(localized: "Generate API key")
        case .rotate: String(localized: "Rotate API key")
        case .delete: String(localized: "Delete API key")
        }
    }

    var message: String {
        switch self {
        case .generate:
            String(localized: "Generate an API key? This key can be used to interact with qBittorrent's API.")
        case .rotate:
            String(localized: "Rotate this API key? The current key will immediately stop working and a new key will be generated.")
        case .delete:
            String(localized: "Delete this API key? The current key will immediately stop working.")
        }
    }
}
