import UniformTypeIdentifiers

/// What a `PathField` picks: a folder, or a file of the given types.
enum PathKind {
    case directory
    case file([UTType])

    var contentTypes: [UTType] {
        switch self {
        case .directory: [.folder]
        case .file(let types): types.isEmpty ? [.item] : types
        }
    }

    /// File types from filename extensions (`dat`, `p2p`, …).
    static func files(_ extensions: String...) -> Self {
        .file(extensions.compactMap { UTType(filenameExtension: $0) })
    }

    /// Live validation like qBittorrent's `FileSystemPathEdit`.
    func warning(for path: String) -> String? {
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let expanded = (trimmed as NSString).expandingTildeInPath
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expanded, isDirectory: &isDirectory) else {
            return String(localized: "Path does not exist")
        }
        switch self {
        case .directory where !isDirectory.boolValue:
            return String(localized: "Path does not point to a directory")
        case .file where isDirectory.boolValue:
            return String(localized: "Path does not point to a file")
        default:
            return FileManager.default.isReadableFile(atPath: expanded) ? nil : String(localized: "Don't have read permission to path")
        }
    }
}
