import AppKit
import UniformTypeIdentifiers

/// Transfer-list actions (toolbar, menus, context menu, keyboard).
extension AppModel {
    // MARK: Plumbing

    /// Runs a synchronous core call; errors become an alert.
    func perform(_ body: (any CoreClient) throws -> Void) {
        guard let client else { return }
        do {
            try body(client)
            refreshSoon()
        } catch {
            present(error)
        }
    }

    /// Runs an async core call off the main actor; errors become an alert.
    func performAsync(_ body: @escaping @Sendable (any CoreClient) async throws -> Void) {
        guard let client else { return }
        Task {
            do {
                try await body(client)
                refreshSoon()
            } catch {
                present(error)
            }
        }
    }

    func present(_ error: Error, title: String? = nil) {
        let qbtError = error as? QbtError
        alert = AppAlert(title: title ?? qbtError?.title ?? String(localized: "Error"), message: error.userMessage)
    }

    func items(_ ids: [String]) -> [TorrentItem] { transfers.items(for: ids) }

    /// Per-torrent DHT/PeX/LSD switches of the Torrent Options dialog.
    func discoveryOptions(_ ids: [String]) -> [TorrentDiscoveryOptions] {
        client?.discoveryOptions(hashes: ids) ?? []
    }

    // MARK: Start / stop

    func start(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        performAsync { try await $0.startTorrents(hashes: ids) }
    }

    func stop(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        performAsync { try await $0.stopTorrents(hashes: ids) }
    }

    func forceStart(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        performAsync { try await $0.setForceStart(hashes: ids, value: true) }
    }

    func startAll() { start(transfers.items.map(\.id)) }
    func stopAll() { stop(transfers.items.map(\.id)) }

    // MARK: Remove

    /// Remove with the confirmation sheet when enabled (Delete key, toolbar).
    func requestRemove(_ ids: [String], deleteFiles: Bool = false) {
        guard !ids.isEmpty else { return }
        if corePreferences.behavior.confirmTorrentDeletion {
            let preselected = deleteFiles || corePreferences.behavior.deleteTorrentContentFiles
            sheet = .removeTorrents(ids: ids, deleteFiles: preselected)
        } else {
            remove(ids, deleteFiles: deleteFiles)
        }
    }

    func remove(_ ids: [String], deleteFiles: Bool) {
        list.selection.subtract(ids)
        performAsync { try await $0.removeTorrents(hashes: ids, deleteFiles: deleteFiles) }
    }

    /// "Remember choice" in the removal dialog.
    func setDeleteFilesByDefault(_ value: Bool) {
        var prefs = corePreferences
        prefs.behavior.deleteTorrentContentFiles = value
        savePreferences(prefs)
    }

    func savePreferences(_ prefs: Preferences) {
        guard let client else { return }
        do {
            try client.setPreferences(prefs: prefs)
            corePreferences = prefs
        } catch {
            present(error)
        }
    }

    // MARK: Recheck / reannounce

    func requestRecheck(_ ids: [String]) {
        let withMetadata = items(ids).filter(\.hasMetadata).map(\.id)
        guard !withMetadata.isEmpty else { return }
        if corePreferences.advanced.confirmTorrentRecheck {
            confirmation = .recheck(ids: withMetadata)
        } else {
            recheck(withMetadata)
        }
    }

    func recheck(_ ids: [String]) {
        performAsync { try await $0.recheckTorrents(hashes: ids) }
    }

    func reannounce(_ ids: [String]) {
        performAsync { try await $0.reannounceTorrents(hashes: ids) }
    }

    /// Whether "Force reannounce" is enabled: any torrent not stopped, checking or queued.
    func canReannounce(_ items: [TorrentItem]) -> Bool {
        items.contains { !$0.state.isStopped && !$0.state.isChecking && !$0.state.isQueued }
    }

    // MARK: Location, rename

    func requestSetLocation(_ ids: [String]) {
        guard let first = items(ids).first else { return }
        fileImport = .setLocation(ids: ids, startPath: first.savePath)
    }

    /// Disables automatic management, then moves the content.
    func setLocation(_ ids: [String], to url: URL) {
        let path = url.path(percentEncoded: false)
        performAsync { client in
            try client.setAutoManagement(hashes: ids, enabled: false)
            try await client.setLocation(hashes: ids, location: path)
        }
    }

    func requestRename(_ id: String) {
        guard let item = transfers.item(id) else { return }
        sheet = .textPrompt(TextPromptRequest(
            title: String(localized: "Rename"), label: String(localized: "New name:"), text: item.name,
            purpose: .renameTorrent(id: id)
        ))
    }

    // MARK: Categories and tags

    func setCategory(_ ids: [String], _ category: String) {
        perform { try $0.setCategory(hashes: ids, category: category) }
    }

    func requestNewCategory(assignTo ids: [String] = [], parent: String? = nil) {
        sheet = .category(CategoryEditorRequest(mode: .new(parent: parent), assignTo: ids))
    }

    func requestEditCategory(_ name: String) {
        guard let category = categories.category(named: name) else { return }
        sheet = .category(CategoryEditorRequest(mode: .edit(category)))
    }

    func requestAddTags(_ ids: [String]) {
        sheet = .textPrompt(TextPromptRequest(
            title: String(localized: "Add tags"), label: String(localized: "Comma-separated tags:"), text: "",
            purpose: .addTags(ids: ids)
        ))
    }

    /// Tri-state tag menu entry: checked → remove from all, otherwise add to all.
    func toggleTag(_ tag: String, for ids: [String]) {
        let selected = items(ids)
        if selected.allSatisfy({ $0.tags.contains(tag) }) {
            perform { try $0.removeTags(hashes: ids, tags: [tag]) }
        } else {
            perform { try $0.addTags(hashes: ids, tags: [tag]) }
        }
    }

    func requestRemoveAllTags(_ ids: [String]) {
        if gui.confirmRemoveAllTags {
            confirmation = .removeAllTags(ids: ids)
        } else {
            removeAllTags(ids)
        }
    }

    func removeAllTags(_ ids: [String]) {
        perform { try $0.removeTags(hashes: ids, tags: []) }
    }

    // MARK: Flags

    func setAutoTMM(_ ids: [String], enabled: Bool) {
        if enabled {
            confirmation = .enableAutoTMM(ids: ids)
        } else {
            perform { try $0.setAutoManagement(hashes: ids, enabled: false) }
        }
    }

    func confirmAutoTMM(_ ids: [String]) {
        perform { try $0.setAutoManagement(hashes: ids, enabled: true) }
    }

    func setSequential(_ ids: [String], _ value: Bool) {
        perform { try $0.setSequentialDownload(hashes: ids, value: value) }
    }

    func setFirstLastPiece(_ ids: [String], _ value: Bool) {
        perform { try $0.setFirstLastPiecePriority(hashes: ids, value: value) }
    }

    func setSuperSeeding(_ ids: [String], _ value: Bool) {
        let withMetadata = items(ids).filter(\.hasMetadata).map(\.id)
        perform { try $0.setSuperSeeding(hashes: withMetadata, value: value) }
    }

    // MARK: Queue

    func queue(_ ids: [String], _ move: QueueMove) {
        guard !ids.isEmpty else { return }
        perform { client in
            switch move {
            case .up: try client.queueIncrease(hashes: ids)
            case .down: try client.queueDecrease(hashes: ids)
            case .top: try client.queueTop(hashes: ids)
            case .bottom: try client.queueBottom(hashes: ids)
            }
        }
    }

    // MARK: Limits

    func setLimits(_ ids: [String], download: Int64?, upload: Int64?) {
        perform { client in
            if let download { try client.setDownloadLimit(hashes: ids, limit: download) }
            if let upload { try client.setUploadLimit(hashes: ids, limit: upload) }
        }
    }

    func setAltSpeedLimits(_ enabled: Bool) {
        client?.setAltSpeedLimitsEnabled(enabled: enabled)
        status.altSpeedEnabled = enabled
        refreshSoon()
    }

    func toggleAltSpeedLimits() { setAltSpeedLimits(!status.altSpeedEnabled) }

    /// Status bar "External IP" item (a core preference).
    var showsExternalIP: Bool {
        get { corePreferences.behavior.statusBarExternalIp }
        set {
            var prefs = corePreferences
            prefs.behavior.statusBarExternalIp = newValue
            savePreferences(prefs)
        }
    }

    /// Global limits of the active mode (normal or alternative), bytes/s.
    var globalDownloadLimit: Int64 {
        get { status.downloadLimit }
        set {
            perform { try $0.setGlobalDownloadLimit(limit: newValue) }
            status.downloadLimit = newValue
        }
    }

    var globalUploadLimit: Int64 {
        get { status.uploadLimit }
        set {
            perform { try $0.setGlobalUploadLimit(limit: newValue) }
            status.uploadLimit = newValue
        }
    }

    /// Bindable alternative-speed mode (menus, status bar toggle).
    var alternativeSpeedLimits: Bool {
        get { status.altSpeedEnabled }
        set { setAltSpeedLimits(newValue) }
    }

    // MARK: Copy, open, preview, export

    func copy(_ kind: CopyKind, ids: [String]) {
        let values = items(ids).compactMap { kind.value(of: $0) }.filter { !$0.isEmpty }
        let separator = kind == .comment ? "\n---------\n" : "\n"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(values.joined(separator: separator), forType: .string)
    }

    /// Reveals the content (or save folder without metadata) in Finder.
    func openDestination(_ ids: [String]) {
        var seen = Set<String>()
        let urls = items(ids).compactMap { item -> URL? in
            let path = item.destinationPath
            guard !path.isEmpty, seen.insert(path).inserted else { return nil }
            return URL(filePath: path)
        }
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func requestPreview(_ id: String) {
        guard let item = transfers.item(id) else { return }
        guard item.hasMetadata else { return }
        sheet = .preview(id: id)
    }

    func requestExport(_ ids: [String]) {
        fileImport = .exportTorrents(ids: ids)
    }

    /// Writes `<name>.torrent` files (with " (N)" on collisions) to `folder`.
    func export(_ ids: [String], to folder: URL) {
        guard let client else { return }
        var failures = 0
        for item in items(ids) {
            do {
                let data = try client.exportTorrent(hash: item.id)
                let base = item.name.replacing("/", with: "_").replacing(":", with: "_")
                var target = folder.appending(path: base + ".torrent")
                var counter = 1
                while FileManager.default.fileExists(atPath: target.path(percentEncoded: false)) {
                    target = folder.appending(path: "\(base) (\(counter)).torrent")
                    counter += 1
                }
                try data.write(to: target)
            } catch {
                failures += 1
                appendLocalLog("Export .torrent file failed. Torrent: \"\(item.name)\". Save path: \"\(folder.path)\". Reason: \"\(error.userMessage)\"")
            }
        }
        if failures > 0 {
            alert = AppAlert(title: String(localized: "Export .torrent file error"),
                             message: String(localized: "Errors occurred when exporting .torrent files. Check execution log for details."))
        }
    }

    // MARK: Double-click / Return

    func performDoubleClick(_ ids: [String]) {
        guard ids.count == 1, let item = transfers.item(ids[0]) else { return }
        let action = item.isFinished ? gui.doubleClickCompleted : gui.doubleClickDownloading
        switch action {
        case .toggleStop:
            if item.state.isStopped { start(ids) } else { stop(ids) }
        case .openDestination:
            openDestination(ids)
        case .previewFile:
            if item.hasMetadata { requestPreview(item.id) } else { openDestination(ids) }
        case .showOptions:
            sheet = .torrentOptions(ids: ids)
        case .noAction:
            break
        }
    }

    // MARK: Sidebar actions

    /// Start/Stop/Remove torrents of the sidebar context menus act on the visible torrents.
    var visibleIDs: [String] { list.visibleItems.map(\.id) }

    func removeCategory(_ name: String) {
        perform { try $0.removeCategories(names: [name]) }
        labels.removeCategories([name])
        if case .category(let selected) = list.categoryFilter, selected == name || selected.hasPrefix(name + "/") {
            list.categoryFilter = .all
        }
    }

    func removeUnusedCategories() {
        let unused = categories.sortedNames.filter { (list.counts.categories[$0] ?? 0) == 0 }
        guard !unused.isEmpty else { return }
        perform { try $0.removeCategories(names: unused) }
        labels.removeCategories(unused)
    }

    func requestAddTag() {
        sheet = .tagEditor(TagEditorRequest(mode: .new))
    }

    func requestEditTag(_ tag: String) {
        sheet = .tagEditor(TagEditorRequest(mode: .edit(tag)))
    }

    func removeTag(_ tag: String) {
        perform { try $0.deleteTags(tags: [tag]) }
        labels.removeTags([tag])
        if list.tagFilter == .tag(tag) { list.tagFilter = .all }
    }

    func removeUnusedTags() {
        let unused = tags.sortedTags.filter { (list.counts.tags[$0] ?? 0) == 0 }
        guard !unused.isEmpty else { return }
        perform { try $0.deleteTags(tags: unused) }
        labels.removeTags(unused)
    }

    func requestRemoveTracker(host: String) {
        if gui.confirmRemoveTrackerFromAllTorrents {
            confirmation = .removeTrackerFromAll(host: host)
        } else {
            removeTracker(host: host)
        }
    }

    func removeTracker(host: String) {
        let entries = trackers.urls(onHost: host)
        perform { client in
            for entry in entries {
                for hash in entry.hashes { try client.removeTrackers(hash: hash, urls: [entry.url]) }
            }
        }
        if list.trackerFilter == .host(host) { list.trackerFilter = .all }
    }

    // MARK: Confirmations

    func confirm(_ confirmation: PendingConfirmation) {
        switch confirmation {
        case .recheck(let ids): recheck(ids)
        case .enableAutoTMM(let ids): confirmAutoTMM(ids)
        case .removeAllTags(let ids): removeAllTags(ids)
        case .banPeers(let peers): perform { try $0.banPeers(peers: peers) }
        case .removeTrackerFromAll(let host): removeTracker(host: host)
        case .mergeTrackers(let hash, _, let trackers, let seeds):
            perform { client in
                try client.addTrackers(hash: hash, trackers: trackers)
                if !seeds.isEmpty { try client.addWebSeeds(hash: hash, urls: seeds) }
            }
        case .clearLockPassword: clearLockPassword()
        }
    }
}
