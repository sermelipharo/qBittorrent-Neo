import Foundation

/// The "Adding entry failed" checks of the watched folder list.
enum WatchedFolderValidator {
    static func error(for path: String, existing: [String]) -> String? {
        let trimmed = path.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return String(localized: "Watched folder path cannot be empty.") }
        if !trimmed.hasPrefix("/") { return String(localized: "Watched folder path cannot be relative.") }
        let normalized = URL(filePath: trimmed).standardizedFileURL.path(percentEncoded: false)
        if existing.contains(where: { URL(filePath: $0).standardizedFileURL.path(percentEncoded: false) == normalized }) {
            return String(localized: "Folder '\(trimmed)' is already in watch list.")
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: trimmed, isDirectory: &isDirectory), isDirectory.boolValue else {
            return String(localized: "Folder '\(trimmed)' doesn't exist.")
        }
        guard FileManager.default.isReadableFile(atPath: trimmed) else {
            return String(localized: "Folder '\(trimmed)' isn't readable.")
        }
        return nil
    }
}
