import AppKit

/// Data loading for the dialogs (trackers to edit, previewable files).
extension AppModel {
    /// Tracker URLs common to all `ids` (by URL), grouped by tier.
    func commonTrackersText(_ ids: [String]) async -> String {
        guard let client else { return "" }
        let lists = await CoreCall.run { () -> [[TrackerEntry]] in
            ids.map { (try? client.trackers(hash: $0)) ?? [] }
        }
        guard var common = lists.first?.filter({ $0.tier >= 0 }) else { return "" }
        for list in lists.dropFirst() {
            let urls = Set(list.map(\.url))
            common.removeAll { !urls.contains($0.url) }
        }
        return TrackerTierParser.format(common.map { TrackerTierEntry(url: $0.url, tier: $0.tier) })
    }

    /// Audio/video files (by extension, as qBittorrent's `isPreviewable`).
    func previewableFiles(_ id: String) async -> [TorrentFile] {
        guard let client else { return [] }
        let files = await CoreCall.run { (try? client.files(hash: id, indexes: [])) ?? [] }
        return files.filter { Self.isPreviewable($0.name) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func openPreview(_ id: String, file: TorrentFile) {
        guard let item = transfers.item(id) else { return }
        let url = URL(filePath: item.savePath).appending(path: file.name)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            alert = AppAlert(title: String(localized: "Preview impossible"),
                             message: String(localized: "Sorry, we can't preview this file: \"\(url.path(percentEncoded: false))\"."))
            return
        }
        NSWorkspace.shared.open(url)
    }

    private static let previewExtensions: Set<String> = [
        "3gp", "aac", "ac3", "aif", "aifc", "aiff", "asf", "au", "avi", "flac", "flv", "m3u", "m4a", "m4p", "m4v", "mid",
        "mkv", "mov", "mp2", "mp3", "mp4", "mpc", "mpe", "mpeg", "mpg", "mpp", "ogg", "ogm", "ogv", "qt", "ra", "ram", "rm",
        "rmv", "rmvb", "swa", "swf", "ts", "vob", "wav", "wma", "wmv", "webm", "opus",
    ]

    static func isPreviewable(_ path: String) -> Bool {
        previewExtensions.contains((path as NSString).pathExtension.lowercased())
    }
}
