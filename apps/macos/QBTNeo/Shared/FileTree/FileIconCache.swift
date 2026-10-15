import AppKit
import UniformTypeIdentifiers

/// Finder icons per file extension (cached), like qBittorrent's macOS
/// `pixmapForExtension`.
@MainActor
enum FileIconCache {
    private static var icons: [String: NSImage] = [:]

    static func icon(forExtension pathExtension: String) -> NSImage {
        let key = pathExtension.lowercased()
        if let icon = icons[key] { return icon }
        let type = UTType(filenameExtension: key) ?? .data
        let icon = NSWorkspace.shared.icon(for: type)
        icons[key] = icon
        return icon
    }

    static let folder: NSImage = NSWorkspace.shared.icon(for: .folder)
}
