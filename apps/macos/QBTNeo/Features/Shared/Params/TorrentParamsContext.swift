import Foundation

/// What the torrent-parameters editor needs to show effective defaults:
/// categories, tags and the global preferences.
struct TorrentParamsContext {
    var categories: [String: Category] = [:]
    var categoryNames: [String] = []
    var tags: [String] = []
    var preferences = Preferences.qbtDefaults

    @MainActor
    init(app: AppModel) {
        categories = app.categories.categories
        categoryNames = app.categories.sortedNames
        tags = app.tags.sortedTags
        preferences = app.corePreferences
    }

    init() {}

    var globalSavePath: String { preferences.downloads.savePath }

    var globalDownloadPath: String {
        preferences.downloads.tempPath.isEmpty ? globalSavePath + "/temp" : preferences.downloads.tempPath
    }

    /// `Session::suggestedSavePath(category, useAutoTMM)`.
    func suggestedSavePath(category: String, automatic: Bool) -> String {
        guard automatic, !category.isEmpty else { return globalSavePath }
        if let path = categories[category]?.savePath, !path.isEmpty {
            return path.hasPrefix("/") ? path : globalSavePath + "/" + path
        }
        return globalSavePath + "/" + category
    }

    func suggestedDownloadPath(category: String) -> String {
        category.isEmpty ? globalDownloadPath : globalDownloadPath + "/" + category
    }

    /// Effective "use another path for incomplete torrents" of a category.
    func usesDownloadPath(category: String) -> Bool {
        guard let option = categories[category]?.downloadPath else { return preferences.downloads.tempPathEnabled }
        switch option {
        case .default: return preferences.downloads.tempPathEnabled
        case .disabled: return false
        default: return true
        }
    }
}
