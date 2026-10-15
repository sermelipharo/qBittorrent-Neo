import CoreTransferable
import Foundation

/// Something dropped on the transfer list: a file/web URL or text (magnets).
enum DroppedItem: Transferable {
    case url(URL)
    case text(String)

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(importing: { (url: URL) in Self.url(url) })
        ProxyRepresentation(importing: { (text: String) in Self.text(text) })
    }
}
