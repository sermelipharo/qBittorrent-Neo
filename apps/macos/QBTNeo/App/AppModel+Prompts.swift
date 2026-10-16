import Foundation

/// Validation and submission of the small text prompts and the category dialog.
extension AppModel {
    /// Applies a prompt's text. Returns an error message to show (keeping the
    /// prompt open), or nil when the prompt can close.
    func submit(_ request: TextPromptRequest, text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        switch request.purpose {
        case .renameTorrent(let id):
            let name = value.replacing("\r\n", with: " ").replacing("\n", with: " ").replacing("\r", with: " ")
            guard !name.isEmpty else { return nil }
            perform { try $0.renameTorrent(hash: id, name: name) }
            return nil

        case .renameFile(let id, let path, let isFolder):
            guard AddTorrentModel.isValidName(value) else {
                return String(localized: "The name is invalid: \"\(value)\"")
            }
            let parent = (path as NSString).deletingLastPathComponent
            let newPath = parent.isEmpty ? value : parent + "/" + value
            guard newPath != path else { return nil }
            performAsync { client in
                if isFolder {
                    try await client.renameFolder(hash: id, oldPath: path, newPath: newPath)
                } else {
                    try await client.renameFile(hash: id, oldPath: path, newPath: newPath)
                }
            }
            return nil

        case .editTracker(let id, let url):
            guard value != url else { return nil }
            guard let parsed = URL(string: value), parsed.scheme != nil, parsed.host() != nil else {
                return String(localized: "The tracker URL entered is invalid.")
            }
            if properties.trackerRows.contains(where: { $0.isRealTracker && $0.url == value }) {
                return String(localized: "The tracker URL already exists.")
            }
            perform { try $0.editTracker(hash: id, origUrl: url, newUrl: value) }
            return nil

        case .addWebSeed(let id):
            guard !value.isEmpty else { return nil }
            if properties.webSeeds.contains(where: { $0.url.caseInsensitiveCompare(value) == .orderedSame }) {
                return String(localized: "This web seed is already in the list.")
            }
            perform { try $0.addWebSeeds(hash: id, urls: [value]) }
            return nil

        case .editWebSeed(let id, let url):
            guard !value.isEmpty, value != url else { return nil }
            if properties.webSeeds.contains(where: { $0.url.caseInsensitiveCompare(value) == .orderedSame }) {
                return String(localized: "This web seed is already in the list.")
            }
            perform { try $0.editWebSeed(hash: id, origUrl: url, newUrl: value) }
            return nil

        case .addTags(let ids):
            let parsed = TagStore.parseCommaSeparated(value)
            if let invalid = parsed.invalid { return String(localized: "Tag name: '\(invalid)' is invalid") }
            guard !parsed.tags.isEmpty else { return nil }
            perform { try $0.addTags(hashes: ids, tags: parsed.tags) }
            return nil
        }
    }

    /// Creates a tag or changes its icon and color. Returns an error message, or nil on success.
    func saveTag(_ request: TagEditorRequest, name: String, appearance: LabelAppearance) -> String? {
        switch request.mode {
        case .new:
            let value = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return nil }
            guard TagStore.isValid(value) else { return String(localized: "Tag name '\(value)' is invalid") }
            guard !tags.contains(value) else { return String(localized: "Tag name already exists.") }
            perform { try $0.createTags(tags: [value]) }
            labels.setTag(value, appearance)
        case .edit(let tag):
            labels.setTag(tag, appearance)
        }
        return nil
    }

    /// Creates or edits a category. Returns an error message, or nil on success.
    func saveCategory(
        _ request: CategoryEditorRequest, name: String, savePath: String, downloadPath: CategoryDownloadPath,
        shareLimits: ShareLimits = ShareLimits(), appearance: LabelAppearance = LabelAppearance()
    ) -> String? {
        let category = Category(name: name, savePath: savePath, downloadPath: downloadPath, shareLimits: shareLimits)
        switch request.mode {
        case .new:
            guard CategoryStore.isValidName(name) else {
                return String(localized: """
                    Category name cannot contain '\\'.
                    Category name cannot start/end with '/'.
                    Category name cannot contain '//' sequence.
                    """)
            }
            guard categories.category(named: name) == nil else {
                return String(localized: "Category with the given name already exists.\nPlease choose a different name and try again.")
            }
            guard let client else { return nil }
            do {
                try client.createCategory(category: category)
                if !request.assignTo.isEmpty { try client.setCategory(hashes: request.assignTo, category: name) }
                labels.setCategory(name, appearance)
                refreshSoon()
                return nil
            } catch {
                return error.userMessage
            }
        case .edit:
            perform { try $0.editCategory(category: category) }
            labels.setCategory(name, appearance)
            return nil
        }
    }
}
