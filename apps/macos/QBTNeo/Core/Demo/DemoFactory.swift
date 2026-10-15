import Foundation

/// Expands `DemoSeed`s into complete demo torrents.
enum DemoFactory {
    static let gib = 1024.0 * 1024 * 1024
    static let downloadsPath = FileManager.default.homeDirectoryForCurrentUser.appending(path: "Downloads").path(percentEncoded: false)

    static func make(_ seed: DemoSeed, now: Int64, categoryPaths: [String: String]) -> DemoTorrent {
        var random = DemoRandom(seed.name)
        let hash = DemoRandom.hex(seed.name, length: 40)
        var info = TorrentInfo.blank(hash: hash)
        info.name = seed.name
        info.infohashV2 = seed.hybrid ? DemoRandom.hex(seed.name + "#v2", length: 64) : ""
        info.category = seed.category
        info.tags = seed.tags
        info.state = seed.state
        info.private = seed.isPrivate
        info.comment = seed.comment
        info.createdBy = random.pick(["mktorrent 1.1", "qBittorrent v5.0.3", "Transmission/4.0.6", "ia_make_torrent", "py3createtorrent 1.2"])
        info.creationDate = now - Int64(seed.addedDaysAgo * 86_400) - Int64(random.int(3_600...2_000_000))
        info.addedOn = now - Int64(seed.addedDaysAgo * 86_400)
        info.savePath = categoryPaths[seed.category].flatMap { $0.isEmpty ? nil : $0 }
            ?? (seed.category.isEmpty ? downloadsPath : downloadsPath + "/" + seed.category)
        info.autoTmm = !seed.category.isEmpty
        info.contentPath = info.savePath + "/" + seed.name
        info.rootPath = info.contentPath
        info.seqDl = seed.sequential
        info.superSeeding = seed.superSeeding
        info.forceStart = seed.state.isForced
        info.queuePosition = seed.queuePosition
        info.errorMessage = seed.error
        info.hasTrackerWarning = seed.trackerWarning
        info.hasTrackerError = seed.trackerError

        let hasMetadata = seed.state != .downloadingMetadata && seed.state != .forcedDownloadingMetadata
        info.hasMetadata = hasMetadata
        let total = Int64(seed.gib * gib)
        var files: [TorrentFile] = []
        var pieces: [UInt8] = []
        if hasMetadata {
            info.totalSize = total
            info.size = total
            info.pieceSize = pieceSize(for: total)
            info.piecesNum = (total + info.pieceSize - 1) / info.pieceSize
            files = makeFiles(seed, total: total, pieceSize: info.pieceSize, random: &random)
            pieces = makePieces(count: Int(info.piecesNum), progress: seed.progress, sequential: seed.sequential,
                                downloading: seed.state == .downloading || seed.state == .forcedDownloading, random: &random)
            info.piecesHave = Int64(pieces.count { $0 == 2 })
        } else {
            info.totalSize = -1
            info.size = 0
        }

        info.progress = seed.progress
        info.completed = Int64(Double(info.size) * seed.progress)
        info.amountLeft = max(info.size - info.completed, 0)
        info.downloaded = info.completed + Int64(Double(info.completed) * 0.012)
        info.uploaded = Int64(Double(max(info.downloaded, 1)) * seed.ratio)
        info.downloadedSession = Int64(Double(info.downloaded) * min(seed.addedDaysAgo, 1) * 0.6)
        info.uploadedSession = Int64(Double(info.uploaded) * 0.08)
        info.ratio = info.downloaded > 0 ? Double(info.uploaded) / Double(info.downloaded) : 0
        info.totalWasted = Int64(Double(info.downloaded) * 0.0007)
        info.timeActive = Int64(seed.addedDaysAgo * 86_400 * 0.82)
        if seed.progress >= 1 {
            info.completionOn = info.addedOn + Int64(random.int(600...14_400))
            info.seedingTime = max(now - info.completionOn, 0) * 8 / 10
            info.lastSeenComplete = now - Int64(random.int(5...600))
        } else if seed.progress > 0.5 {
            info.lastSeenComplete = now - Int64(random.int(600...90_000))
        }
        let months = Double(info.timeActive) / (30 * 86_400)
        info.popularity = months > 0 ? info.ratio / months : 0

        let hosts = seed.hosts
        let trackers = makeTrackers(hosts: hosts, seed: seed, random: &random, now: now)
        info.trackersCount = Int64(trackers.count)
        info.tracker = trackers.first(where: { $0.status == .working })?.url ?? trackers.first?.url ?? ""
        info.magnetUri = magnet(hash: hash, name: seed.name, trackers: trackers.map(\.url))
        info.numComplete = Int64(random.int(12...900))
        info.numIncomplete = Int64(random.int(3...300))
        info.connectionsLimit = 100
        info.reannounce = info.state.isStopped ? 0 : Int64(random.int(30...1_800))
        info.lastActivity = info.state.isStopped ? now - Int64(random.int(3_600...400_000)) : now - Int64(random.int(1...40))

        let down = seed.downKiB * 1024
        let up = seed.upKiB * 1024
        return DemoTorrent(
            info: info, files: files, trackers: trackers,
            webSeeds: seed.hosts.contains { $0.contains("archive.org") } ? ["https://archive.org/download/\(hash.prefix(12))/"] : [],
            pieces: pieces, baseDown: down, baseUp: up, seed: DemoRandom.hash(seed.name)
        )
    }

    /// Generated torrents for the 2,000-row stress test.
    static func largeSeeds(count: Int) -> [DemoSeed] {
        var random = DemoRandom(seed: 2_000)
        let states: [TorrentState] = [
            .downloading, .stalledDownloading, .uploading, .stalledUploading, .stalledUploading, .stoppedUploading,
            .stoppedDownloading, .queuedDownloading, .uploading, .stalledUploading,
        ]
        let categories = DemoCatalog.categories.map(\.name) + [""]
        return (0..<count).map { index in
            let prefix = random.pick(DemoCatalog.largeNamePrefixes)
            let kind = random.pick(DemoCatalog.largeNameKinds)
            let state = random.pick(states)
            let progress = state.isCompleted || state == .stoppedUploading ? 1 : random.unit() * 0.98
            let active = state == .downloading || state == .uploading
            return DemoSeed(
                name: "\(prefix)-\(random.int(1...40)).\(random.int(0...12))-\(index)-\(kind)",
                gib: 0.2 + random.unit() * 12, state: state, progress: progress,
                category: random.pick(categories),
                tags: random.unit() < 0.3 ? [random.pick(DemoCatalog.tags)] : [],
                hosts: [random.pick(["tracker.opentrackr.org", "tracker.torrent.eu.org", "open.stealth.si", "academictorrents.com"])],
                ratio: progress >= 1 ? random.unit() * 5 : 0,
                addedDaysAgo: random.unit() * 300,
                downKiB: active && progress < 1 ? random.unit() * 3_000 : 0,
                upKiB: active ? random.unit() * 800 : 0
            )
        }
    }

    // MARK: Pieces and files

    static func pieceSize(for total: Int64) -> Int64 {
        var size: Int64 = 16 * 1024
        while total / size > 2_000, size < 16 * 1024 * 1024 { size *= 2 }
        return size
    }

    private static func makeFiles(_ seed: DemoSeed, total: Int64, pieceSize: Int64, random: inout DemoRandom) -> [TorrentFile] {
        let entries: [(String, Double)] = switch seed.layout {
        case .single: [(seed.name, 1)]
        case .files(let list): list.map { (seed.name + "/" + $0.0, $0.1) }
        }
        var offset: Int64 = 0
        var files: [TorrentFile] = []
        for (index, entry) in entries.enumerated() {
            let size = index == entries.count - 1 ? total - offset : max(Int64(Double(total) * entry.1), 1)
            var progress: Double
            if seed.progress >= 1 {
                progress = 1
            } else if seed.sequential {
                let done = Double(total) * seed.progress - Double(offset)
                progress = min(max(done / Double(size), 0), 1)
            } else {
                progress = size < 2_000_000 ? 1 : min(max(seed.progress + (random.unit() - 0.5) * 0.2, 0), 1)
            }
            let first = offset / pieceSize
            let last = max((offset + size - 1) / pieceSize, first)
            let priority: FilePriority = entry.0.hasSuffix(".txt") && seed.progress < 1 ? .ignored : (index == 0 ? .high : .normal)
            if priority == .ignored { progress = 0 }
            files.append(TorrentFile(
                index: Int64(index), name: entry.0, size: size, progress: progress, priority: priority,
                isSeed: progress >= 1, pieceRange: [first, last],
                availability: seed.progress >= 1 ? -1 : min(1, 0.6 + random.unit() * 0.5)
            ))
            offset += size
        }
        return files
    }

    static func makePieces(count: Int, progress: Double, sequential: Bool, downloading: Bool, random: inout DemoRandom) -> [UInt8] {
        guard count > 0 else { return [] }
        if progress >= 1 { return [UInt8](repeating: 2, count: count) }
        var pieces = [UInt8](repeating: 0, count: count)
        if sequential {
            let have = Int(Double(count) * progress)
            for index in 0..<have { pieces[index] = 2 }
            if downloading {
                for index in have..<min(have + 12, count) { pieces[index] = 1 }
            }
        } else {
            // Clustered random completion, which looks like a real swarm download.
            var index = 0
            while index < count {
                let run = random.int(1...max(count / 60, 2))
                let have = random.unit() < progress
                for offset in index..<min(index + run, count) { pieces[offset] = have ? 2 : 0 }
                index += run
            }
            if downloading {
                for _ in 0..<min(24, max(count / 80, 3)) {
                    let piece = random.int(0...(count - 1))
                    if pieces[piece] == 0 { pieces[piece] = 1 }
                }
            }
        }
        return pieces
    }

    // MARK: Trackers

    private static func makeTrackers(hosts: [String], seed: DemoSeed, random: inout DemoRandom, now: Int64) -> [TrackerEntry] {
        hosts.enumerated().map { index, host in
            let url = host.contains("archive.org") || host.contains("ubuntu") || host.contains("fedora")
                ? "https://\(host)/announce"
                : (index.isMultiple(of: 2) ? "udp://\(host):1337/announce" : "https://\(host)/announce")
            var status: TrackerStatus = seed.state.isStopped ? .notContacted : .working
            var message = ""
            if seed.trackerError && index == 0 {
                status = .trackerError
                message = "Torrent not registered with this tracker"
            } else if seed.trackerWarning && index == 0 {
                message = "Announce interval raised to 1800s due to load"
            }
            let seeds = Int64(random.int(5...900))
            let leeches = Int64(random.int(1...300))
            let downloaded = Int64(random.int(100...40_000))
            let next = status == .working ? Int64(random.int(60...1_800)) : 0
            let peers = status == .working ? Int64(random.int(10...50)) : 0
            let endpoints = ["192.168.1.24:51413", "[2a02:810d:4b40:7e00::24]:51413"].map { endpoint in
                TrackerEndpoint(
                    name: endpoint, updating: false, status: status, message: message, btVersion: 1, numPeers: peers,
                    numSeeds: seeds, numLeeches: leeches, numDownloaded: downloaded, nextAnnounce: next, minAnnounce: min(next, 900)
                )
            }
            return TrackerEntry(
                url: url, tier: Int64(index), status: status, updating: false, message: message, numPeers: peers,
                numSeeds: seeds, numLeeches: leeches, numDownloaded: downloaded, nextAnnounce: next,
                minAnnounce: min(next, 900), endpoints: endpoints
            )
        }
    }

    static func magnet(hash: String, name: String, trackers: [String]) -> String {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+"))
        var link = "magnet:?xt=urn:btih:\(hash)"
        if let encoded = name.addingPercentEncoding(withAllowedCharacters: allowed) { link += "&dn=\(encoded)" }
        for tracker in trackers {
            if let encoded = tracker.addingPercentEncoding(withAllowedCharacters: allowed) { link += "&tr=\(encoded)" }
        }
        return link
    }
}
