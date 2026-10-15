import Foundation

// Mutations behind the `CoreClient` actions, so the demo app reacts to
// everything the UI can do.
extension DemoState {
    func torrent(_ hash: String) throws -> DemoTorrent {
        guard let torrent = torrents[hash] else { throw QbtError.NotFound(message: "torrent \(hash)") }
        return torrent
    }

    mutating func update(_ hashes: [String], _ body: (inout DemoTorrent) -> Void) {
        for hash in hashes {
            guard var torrent = torrents[hash] else { continue }
            body(&torrent)
            torrents[hash] = torrent
        }
    }

    mutating func start(_ hashes: [String], forced: Bool) {
        update(hashes) { torrent in
            let done = torrent.info.progress >= 1
            torrent.info.forceStart = forced
            torrent.info.errorMessage = ""
            if forced {
                torrent.info.state = done ? .forcedUploading : .forcedDownloading
            } else if done {
                torrent.info.state = torrent.baseUp > 0 ? .uploading : .stalledUploading
            } else {
                if torrent.baseDown == 0 { torrent.baseDown = 1_800 * 1024 }
                torrent.info.state = .downloading
            }
        }
        step(now: Date.now.timeIntervalSince1970, force: true)
    }

    mutating func stop(_ hashes: [String]) {
        update(hashes) { torrent in
            torrent.info.forceStart = false
            torrent.info.state = torrent.info.progress >= 1 ? .stoppedUploading : .stoppedDownloading
            torrent.transientSeconds = 0
        }
        step(now: Date.now.timeIntervalSince1970, force: true)
    }

    mutating func remove(_ hashes: [String]) {
        for hash in hashes {
            guard let torrent = torrents.removeValue(forKey: hash) else { continue }
            order.removeAll { $0 == hash }
            events.append(.torrentRemoved(hash: hash, name: torrent.info.name))
            appendLog(.info, "Removed torrent. Torrent: \"\(torrent.info.name)\"")
        }
    }

    mutating func recheck(_ hashes: [String]) {
        update(hashes) { torrent in
            let done = torrent.info.progress >= 1
            torrent.stateAfterTransient = torrent.info.state.isStopped ? torrent.info.state : (done ? .stalledUploading : .downloading)
            torrent.info.state = done ? .checkingUploading : .checkingDownloading
            torrent.transientSeconds = 6
        }
    }

    mutating func setLocation(_ hashes: [String], path: String) {
        update(hashes) { torrent in
            torrent.info.autoTmm = false
            torrent.info.savePath = path
            torrent.info.contentPath = path + "/" + torrent.info.name
            torrent.info.rootPath = torrent.info.contentPath
            torrent.stateAfterTransient = torrent.info.state
            torrent.info.state = .moving
            torrent.transientSeconds = 4
        }
    }

    mutating func addTrackers(_ hash: String, _ entries: [TrackerTierEntry]) {
        update([hash]) { torrent in
            for entry in entries where !torrent.trackers.contains(where: { $0.url == entry.url }) {
                torrent.trackers.append(TrackerEntry(
                    url: entry.url, tier: entry.tier, status: .notContacted, updating: false, message: "", numPeers: -1,
                    numSeeds: -1, numLeeches: -1, numDownloaded: -1, nextAnnounce: 0, minAnnounce: 0, endpoints: []
                ))
            }
            torrent.info.trackersCount = Int64(torrent.trackers.count)
        }
    }

    mutating func replaceTrackers(_ hash: String, _ entries: [TrackerTierEntry]) {
        update([hash]) { torrent in
            let existing = Dictionary(torrent.trackers.map { ($0.url, $0) }, uniquingKeysWith: { first, _ in first })
            torrent.trackers = entries.map { entry in
                var tracker = existing[entry.url] ?? TrackerEntry(
                    url: entry.url, tier: entry.tier, status: .notContacted, updating: false, message: "", numPeers: -1,
                    numSeeds: -1, numLeeches: -1, numDownloaded: -1, nextAnnounce: 0, minAnnounce: 0, endpoints: []
                )
                tracker.tier = entry.tier
                return tracker
            }
            torrent.info.trackersCount = Int64(torrent.trackers.count)
            torrent.info.tracker = torrent.trackers.first?.url ?? ""
        }
    }

    mutating func moveQueue(_ hashes: [String], _ move: QueueMove) {
        let queued = order.filter { (torrents[$0]?.info.queuePosition ?? 0) > 0 }
            .sorted { (torrents[$0]?.info.queuePosition ?? 0) < (torrents[$1]?.info.queuePosition ?? 0) }
        var list = queued
        let selected = Set(hashes)
        switch move {
        case .top:
            list = list.filter(selected.contains) + list.filter { !selected.contains($0) }
        case .bottom:
            list = list.filter { !selected.contains($0) } + list.filter(selected.contains)
        case .up:
            for index in list.indices.dropFirst() where selected.contains(list[index]) && !selected.contains(list[index - 1]) {
                list.swapAt(index, index - 1)
            }
        case .down:
            for index in list.indices.dropLast().reversed() where selected.contains(list[index]) && !selected.contains(list[index + 1]) {
                list.swapAt(index, index + 1)
            }
        }
        for (position, hash) in list.enumerated() {
            torrents[hash]?.info.queuePosition = Int64(position + 1)
        }
    }

    mutating func createCategory(_ category: Category) throws {
        guard categories[category.name] == nil else {
            throw QbtError.Conflict(message: "Category with the given name already exists.")
        }
        for ancestor in CategoryStore.ancestors(of: category.name) where categories[ancestor] == nil {
            categories[ancestor] = Category(name: ancestor, savePath: "", downloadPath: .default)
        }
        categories[category.name] = category
    }

    mutating func removeCategories(_ names: [String]) {
        for name in names {
            let doomed = categories.keys.filter { $0 == name || $0.hasPrefix(name + "/") }
            for key in doomed { categories[key] = nil }
            let parent = CategoryStore.ancestors(of: name).last ?? ""
            for hash in order {
                let category = torrents[hash]?.info.category ?? ""
                if category == name || category.hasPrefix(name + "/") { torrents[hash]?.info.category = parent }
            }
        }
    }

    mutating func setCategory(_ hashes: [String], _ category: String) {
        if !category.isEmpty, categories[category] == nil {
            try? createCategory(Category(name: category, savePath: "", downloadPath: .default))
        }
        update(hashes) { $0.info.category = category }
    }

    mutating func addTags(_ hashes: [String], _ newTags: [String]) {
        tags.formUnion(newTags)
        update(hashes) { torrent in
            for tag in newTags where !torrent.info.tags.contains(tag) { torrent.info.tags.append(tag) }
            torrent.info.tags.sort { $0.localizedStandardCompare($1) == .orderedAscending }
        }
    }

    mutating func removeTags(_ hashes: [String], _ removed: [String]) {
        update(hashes) { torrent in
            torrent.info.tags = removed.isEmpty ? [] : torrent.info.tags.filter { !removed.contains($0) }
        }
    }

    mutating func deleteTags(_ removed: [String]) {
        tags.subtract(removed)
        removeTags(order, removed)
    }

    mutating func renameFile(_ hash: String, old: String, new: String, folder: Bool) throws {
        guard var torrent = torrents[hash] else { throw QbtError.NotFound(message: hash) }
        if !folder, torrent.files.contains(where: { $0.name == new }) {
            throw QbtError.Conflict(message: "The file already exists: '\(new)'.")
        }
        var found = false
        for index in torrent.files.indices {
            let name = torrent.files[index].name
            if folder, name.hasPrefix(old + "/") {
                torrent.files[index].name = new + name.dropFirst(old.count)
                found = true
            } else if !folder, name == old {
                torrent.files[index].name = new
                found = true
            }
        }
        guard found else {
            throw QbtError.NotFound(message: folder ? "No such folder: '\(old)'." : "No such file: '\(old)'.")
        }
        torrents[hash] = torrent
    }

    mutating func addTorrent(_ source: TorrentSource, params: AddTorrentParams) throws -> String {
        var metadata = Self.sampleMetadata(for: source, existing: torrents)
        if let fetched = fetched[metadata.hash] { metadata = fetched }
        guard torrents[metadata.hash] == nil else {
            events.append(.duplicateTorrent(hash: metadata.hash, name: metadata.name, mergedTrackers: false))
            throw QbtError.Conflict(message: "This torrent is already in the transfer list.")
        }
        let name = params.name ?? metadata.name
        let stopped = params.stopped ?? preferences.downloads.addStoppedEnabled
        let seed = DemoSeed(
            name: name, gib: Double(max(metadata.totalSize, 1)) / DemoFactory.gib,
            state: stopped ? .stoppedDownloading : .downloading, progress: 0, category: params.category ?? "",
            tags: params.tags, hosts: metadata.trackers.compactMap { URL(string: $0.url)?.host() }, addedDaysAgo: 0,
            comment: metadata.comment, downKiB: 3_200, upKiB: 240, sequential: params.sequential
        )
        let paths = Dictionary(uniqueKeysWithValues: categories.values.map { ($0.name, $0.savePath) })
        var torrent = DemoFactory.make(seed, now: Int64(Date.now.timeIntervalSince1970), categoryPaths: paths)
        if let savePath = params.savePath, !savePath.isEmpty { torrent.info.savePath = savePath }
        if !metadata.files.isEmpty {
            var offset: Int64 = 0
            let pieceSize = DemoFactory.pieceSize(for: metadata.totalSize)
            torrent.files = metadata.files.enumerated().map { index, file in
                defer { offset += file.size }
                let priority = params.filePriorities.indices.contains(index) ? params.filePriorities[index] : .normal
                let path = params.filePaths.indices.contains(index) ? params.filePaths[index] : file.path
                return TorrentFile(
                    index: file.index, name: path, size: file.size, progress: 0, priority: priority, isSeed: false,
                    pieceRange: [offset / pieceSize, (offset + max(file.size, 1) - 1) / pieceSize], availability: 0.8
                )
            }
        }
        if !params.tags.isEmpty { tags.formUnion(params.tags) }
        if let category = params.category, !category.isEmpty, categories[category] == nil {
            categories[category] = Category(name: category, savePath: "", downloadPath: .default)
        }
        torrent.info.queuePosition = (order.compactMap { torrents[$0]?.info.queuePosition }.max() ?? 0) + 1
        order.append(torrent.hash)
        torrents[torrent.hash] = torrent
        events.append(.torrentAdded(hash: torrent.hash, name: name))
        appendLog(.info, "Added new torrent. Torrent: \"\(name)\"")
        return torrent.hash
    }

    /// Plausible metadata for any source (the demo does not parse files).
    static func sampleMetadata(for source: TorrentSource, existing: [String: DemoTorrent]) -> TorrentMetadataInfo {
        let name: String
        switch source {
        case .url(let url):
            if url.lowercased().hasPrefix("magnet:"),
               let components = URLComponents(string: url),
               let display = components.queryItems?.first(where: { $0.name == "dn" })?.value {
                name = display
            } else if url.lowercased().hasPrefix("magnet:") {
                name = "Magnet link"
            } else {
                name = ((URL(string: url)?.lastPathComponent ?? url) as NSString).deletingPathExtension
            }
        case .file(let path):
            name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        case .bytes:
            name = "Elephants Dream (2006) [1080p]"
        }
        let hash = DemoRandom.hex(name, length: 40)
        let gib = DemoFactory.gib
        let files: [(String, Double)] = [
            ("\(name).mkv", 3.82 * gib), ("Sample/\(name) - sample.mkv", 0.061 * gib),
            ("Subs/English.srt", 0.00009 * gib), ("Subs/German.srt", 0.00008 * gib), ("Subs/Spanish.srt", 0.00008 * gib),
            ("Extras/Behind the scenes.mp4", 0.44 * gib), ("Extras/Storyboards.pdf", 0.012 * gib), ("\(name).nfo", 0.000004 * gib),
        ]
        let metadataFiles = files.enumerated().map { index, file in
            MetadataFile(index: Int64(index), path: "\(name)/\(file.0)", size: Int64(file.1))
        }
        return TorrentMetadataInfo(
            hash: hash, infohashV1: hash, infohashV2: DemoRandom.hex(name + "#v2", length: 64), name: name, hasMetadata: true,
            totalSize: metadataFiles.reduce(0) { $0 + $1.size }, pieceSize: 4 * 1_048_576, piecesNum: 1_100, private: false,
            comment: "Orange Open Movie Project — https://orange.blender.org", createdBy: "mktorrent 1.1",
            creationDate: Int64(Date.now.timeIntervalSince1970) - 86_400 * 41, files: metadataFiles,
            trackers: [
                TrackerTierEntry(url: "udp://tracker.opentrackr.org:1337/announce", tier: 0),
                TrackerTierEntry(url: "https://tracker.torrent.eu.org/announce", tier: 1),
            ],
            urlSeeds: [], isDuplicate: existing[hash] != nil
        )
    }
}
