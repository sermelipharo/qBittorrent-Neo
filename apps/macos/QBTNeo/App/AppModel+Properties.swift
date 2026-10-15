import AppKit

/// Actions of the properties tabs (trackers, peers, HTTP sources, content).
extension AppModel {
    func copyToPasteboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    // MARK: Trackers

    /// Real tracker URLs among table row IDs (sticky and endpoint rows excluded).
    func trackerURLs(rowIDs: Set<String>) -> [String] {
        properties.trackerRows.filter { rowIDs.contains($0.id) && $0.isRealTracker }.map(\.url)
    }

    func selectedTrackerURLs() -> [String] { trackerURLs(rowIDs: properties.trackerSelection) }

    func requestEditTracker(hash: String, rowIDs: Set<String>) {
        guard let url = trackerURLs(rowIDs: rowIDs).last else { return }
        sheet = .textPrompt(TextPromptRequest(
            title: String(localized: "Tracker editing"), label: String(localized: "Tracker URL:"), text: url,
            purpose: .editTracker(id: hash, url: url)
        ))
    }

    func removeSelectedTrackers(hash: String) {
        let urls = selectedTrackerURLs()
        guard !urls.isEmpty else { return }
        perform { try $0.removeTrackers(hash: hash, urls: urls) }
    }

    func trackerURLProviders() -> [NSItemProvider] {
        let urls = selectedTrackerURLs()
        return urls.isEmpty ? [] : [NSItemProvider(object: urls.joined(separator: "\n") as NSString)]
    }

    /// Tier − 1 (floor 0) or + 1 for the selected trackers; rewrites the list.
    func shiftTrackerTiers(hash: String, by delta: Int64) {
        let selected = Set(selectedTrackerURLs())
        guard !selected.isEmpty else { return }
        let entries = properties.trackerEntries.filter { $0.tier >= 0 }.map { entry in
            TrackerTierEntry(url: entry.url, tier: selected.contains(entry.url) ? max(entry.tier + delta, 0) : entry.tier)
        }
        perform { try $0.replaceTrackers(hash: hash, trackers: entries) }
    }

    // MARK: Peers

    func requestAddPeers(_ item: TorrentItem) {
        sheet = .addPeers(ids: [item.id])
    }

    /// Why "Add peers…" is disabled for this torrent, if it is.
    func addPeersDisabledReason(_ item: TorrentItem) -> String? {
        if item.isPrivate == true { return String(localized: "Cannot add peers to a private torrent") }
        if item.state.isChecking { return String(localized: "Cannot add peers when the torrent is checking") }
        if item.state.isQueued { return String(localized: "Cannot add peers when the torrent is queued") }
        return nil
    }

    func selectedPeers(_ ids: Set<String>) -> [PeerRow] {
        properties.peers.filter { ids.contains($0.id) }
    }

    func copyPeers(_ ids: Set<String>) {
        copyToPasteboard(selectedPeers(ids).map(\.endpoint).joined(separator: "\n"))
    }

    func requestBanPeers(_ ids: Set<String>) {
        let peers = selectedPeers(ids).map(\.info.ip)
        guard !peers.isEmpty else { return }
        confirmation = .banPeers(peers: peers)
    }

    // MARK: HTTP sources

    func requestAddWebSeed(_ hash: String) {
        sheet = .textPrompt(TextPromptRequest(
            title: String(localized: "Add web seed"), label: String(localized: "Add web seed:"), text: "http://www.",
            purpose: .addWebSeed(id: hash)
        ))
    }

    func requestEditWebSeed(_ hash: String, url: String) {
        sheet = .textPrompt(TextPromptRequest(
            title: String(localized: "Web seed editing"), label: String(localized: "Web seed URL:"), text: url,
            purpose: .editWebSeed(id: hash, url: url)
        ))
    }

    func removeWebSeeds(_ hash: String, urls: [String]) {
        guard !urls.isEmpty else { return }
        perform { try $0.removeWebSeeds(hash: hash, urls: urls) }
    }

    // MARK: Content

    /// Sends priority changes produced by the file tree to the core.
    func applyFilePriorities(_ hash: String, _ changes: [FilePriority: [Int64]]) {
        guard !changes.isEmpty else { return }
        perform { client in
            for (priority, indexes) in changes {
                try client.setFilePriority(hash: hash, indexes: indexes, priority: priority)
            }
        }
    }

    /// On-disk URL of a content node.
    func contentURL(_ item: TorrentItem, _ node: FileNode) -> URL {
        URL(filePath: item.savePath).appending(path: node.path)
    }

    func openContent(_ item: TorrentItem, _ node: FileNode) {
        let url = contentURL(item, node)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            alert = AppAlert(title: String(localized: "Open failed"),
                             message: String(localized: "The file \"\(url.path(percentEncoded: false))\" does not exist yet."))
            return
        }
        NSWorkspace.shared.open(url)
    }

    func revealContent(_ item: TorrentItem, _ node: FileNode) {
        NSWorkspace.shared.activateFileViewerSelecting([contentURL(item, node)])
    }

    func requestRenameContent(_ item: TorrentItem, _ node: FileNode) {
        sheet = .textPrompt(TextPromptRequest(
            title: String(localized: "Renaming"), label: String(localized: "New name:"), text: node.name,
            selectsBaseName: !node.isFolder, purpose: .renameFile(id: item.id, path: node.path, isFolder: node.isFolder)
        ))
    }
}
