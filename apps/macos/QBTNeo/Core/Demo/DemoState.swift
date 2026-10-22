import Foundation

/// The demo session: torrents, categories, tags, preferences and a simple
/// transfer simulation. Guarded by a mutex inside `DemoClient`.
struct DemoState: Sendable {
    var order: [String] = []
    var torrents: [String: DemoTorrent] = [:]
    var categories: [String: Category] = [:]
    var tags: Set<String> = []
    var preferences = Preferences.qbtDefaults
    var altSpeed = false
    var listener: (any EventListener)?
    var events: [CoreEvent] = []
    var log: [LogMessage] = []
    var fetched: [String: TorrentMetadataInfo] = [:]
    var animated: Bool
    var startTime: Double
    var lastTick: Double
    var allTimeDownload: Double = 812 * DemoFactory.gib
    var allTimeUpload: Double = 2_310 * DemoFactory.gib
    var sessionDownload: Double = 0
    var sessionUpload: Double = 0

    // Last values sent by `syncMainData` (for diffs).
    private var rid: Int64 = 0
    /// Hash of the last record sent per torrent (a full copy would double the data).
    private var sentTorrents: [String: Int] = [:]
    private var sentCategories: [String: Category] = [:]
    private var sentTags: Set<String> = []
    private var sentTrackers: [String: [String]] = [:]

    init(large: Bool, animated: Bool) {
        self.animated = animated
        let now = Date.now.timeIntervalSince1970
        startTime = now
        lastTick = now
        preferences.bittorrent.queueingEnabled = true
        preferences.behavior.statusBarExternalIp = true
        preferences.downloads.savePath = DemoFactory.downloadsPath
        preferences.speed.altDlLimit = 1_024 * 1_024
        preferences.speed.altUpLimit = 256 * 1_024
        for (name, path) in DemoCatalog.categories {
            categories[name] = Category(name: name, savePath: path, downloadPath: .default)
        }
        tags = Set(DemoCatalog.tags)
        let seeds = large ? DemoCatalog.seeds + DemoFactory.largeSeeds(count: 2_000 - DemoCatalog.seeds.count) : DemoCatalog.seeds
        let paths = Dictionary(uniqueKeysWithValues: DemoCatalog.categories.map { ($0.name, $0.path) })
        var queue: Int64 = 0
        for seed in seeds {
            var torrent = DemoFactory.make(seed, now: Int64(now), categoryPaths: paths)
            if torrent.info.progress < 1 || torrent.info.state.isDownloading {
                queue += 1
                torrent.info.queuePosition = queue
            }
            if torrent.info.state.isChecking || torrent.info.state == .moving {
                torrent.transientSeconds = 25
                torrent.stateAfterTransient = torrent.info.progress >= 1 ? .stalledUploading : .downloading
                if torrent.baseDown == 0 && torrent.info.progress < 1 { torrent.baseDown = 2_400 * 1024 }
            }
            guard torrents[torrent.hash] == nil else { continue }
            order.append(torrent.hash)
            torrents[torrent.hash] = torrent
        }
        appendInitialLog(now: now)
        step(now: now, force: true)
    }

    // MARK: Simulation

    mutating func step(now: Double, force: Bool = false) {
        let elapsed = animated ? min(max(now - lastTick, 0), 5) : 0
        guard force || elapsed > 0 else { return }
        lastTick = now
        let time = animated ? now - startTime : 120
        let nowSeconds = Int64(now)
        let limits = effectiveLimits()
        for hash in order {
            guard var torrent = torrents[hash] else { continue }
            advance(&torrent, elapsed: elapsed, time: time, now: nowSeconds, limits: limits)
            torrents[hash] = torrent
        }
    }

    private mutating func advance(_ torrent: inout DemoTorrent, elapsed: Double, time: Double, now: Int64, limits: (down: Int64, up: Int64)) {
        var info = torrent.info
        if torrent.transientSeconds > 0 {
            torrent.transientSeconds -= elapsed
            if torrent.transientSeconds <= 0, let next = torrent.stateAfterTransient {
                info.state = next
                torrent.stateAfterTransient = nil
            }
        }
        let wave = DemoRandom.wave(time, seed: torrent.seed)
        let wave2 = DemoRandom.wave(time * 1.3, seed: torrent.seed &* 31)
        var down = 0.0
        var up = 0.0
        switch info.state {
        case .downloading, .forcedDownloading:
            down = torrent.baseDown * (0.55 + 0.9 * wave)
            up = torrent.baseUp * (0.4 + wave2)
        case .uploading, .forcedUploading:
            up = torrent.baseUp * (0.5 + wave2)
        default:
            break
        }
        if info.dlLimit > 0 { down = min(down, Double(info.dlLimit)) }
        if info.upLimit > 0 { up = min(up, Double(info.upLimit)) }
        if limits.down > 0 { down = min(down, Double(limits.down) / 3) }
        if limits.up > 0 { up = min(up, Double(limits.up) / 4) }
        info.dlSpeed = Int64(down)
        info.upSpeed = Int64(up)

        if elapsed > 0, info.size > 0 {
            let gained = down * elapsed
            info.completed = min(info.completed + Int64(gained), info.size)
            info.downloaded += Int64(gained)
            info.downloadedSession += Int64(gained)
            info.uploaded += Int64(up * elapsed)
            info.uploadedSession += Int64(up * elapsed)
            sessionDownload += gained
            sessionUpload += up * elapsed
            allTimeDownload += gained
            allTimeUpload += up * elapsed
            let oldProgress = info.progress
            info.progress = Double(info.completed) / Double(info.size)
            fillPieces(&torrent, from: oldProgress, to: info.progress)
            if !info.state.isStopped { info.timeActive += Int64(elapsed.rounded()) }
            if info.progress >= 1, oldProgress < 1 { finish(&torrent, info: &info, now: now) }
            if info.state.isUploading { info.seedingTime += Int64(elapsed.rounded()) }
        }

        info.amountLeft = max(info.size - info.completed, 0)
        info.ratio = info.downloaded > 0 ? Double(info.uploaded) / Double(info.downloaded) : 0
        info.eta = info.state.isStopped || down <= 0 ? 8_640_000 : Int64(Double(info.amountLeft) / down)
        if down > 0 || up > 0 { info.lastActivity = now }
        let running = !info.state.isStopped && !info.state.isQueued && !info.state.isChecking && info.state != .moving
        if running {
            let isDownloading = info.progress < 1
            info.numSeeds = isDownloading ? Int64(4 + Int(wave * 30)) : Int64(wave2 * 2)
            info.numLeechs = isDownloading ? Int64(1 + Int(wave2 * 9)) : Int64(Int(wave * 10))
            if info.state == .stalledDownloading || info.state == .stalledUploading {
                info.numSeeds = 0
                info.numLeechs = info.state == .stalledUploading ? 0 : Int64(Int(wave * 2))
            }
            info.availability = isDownloading ? 0.6 + wave * 3 : 6 + wave * 20
        } else {
            info.numSeeds = 0
            info.numLeechs = 0
            info.availability = -1
        }
        info.connectionsCount = info.numSeeds + info.numLeechs
        torrent.info = info
    }

    private mutating func finish(_ torrent: inout DemoTorrent, info: inout TorrentInfo, now: Int64) {
        info.progress = 1
        info.completionOn = now
        info.state = torrent.baseUp > 0 ? .uploading : .stalledUploading
        info.queuePosition = 0
        for index in torrent.files.indices where torrent.files[index].priority != .ignored {
            torrent.files[index].progress = 1
            torrent.files[index].isSeed = true
        }
        torrent.pieces = [UInt8](repeating: 2, count: torrent.pieces.count)
        info.piecesHave = Int64(torrent.pieces.count)
        events.append(.torrentFinished(hash: info.hash, name: info.name))
        appendLog(.info, "Torrent download finished. Torrent: \"\(info.name)\"")
    }

    private func fillPieces(_ torrent: inout DemoTorrent, from old: Double, to new: Double) {
        let count = torrent.pieces.count
        guard count > 0 else { return }
        var flips = Int((new - old) * Double(count))
        if flips <= 0 { return }
        for index in torrent.pieces.indices where torrent.pieces[index] != 2 {
            torrent.pieces[index] = 2
            flips -= 1
            if flips == 0 { break }
        }
        torrent.info.piecesHave = Int64(torrent.pieces.count { $0 == 2 })
        for index in torrent.files.indices where torrent.files[index].priority != .ignored && torrent.files[index].progress < 1 {
            torrent.files[index].progress = min(torrent.files[index].progress + (new - old), 1)
        }
    }

    func effectiveLimits() -> (down: Int64, up: Int64) {
        altSpeed
            ? (preferences.speed.altDlLimit, preferences.speed.altUpLimit)
            : (preferences.speed.dlLimit, preferences.speed.upLimit)
    }

    // MARK: Sync

    mutating func mainData() -> MainDataUpdate {
        step(now: Date.now.timeIntervalSince1970)
        rid += 1
        let full = rid == 1
        var changed: [TorrentInfo] = []
        var next: [String: Int] = [:]
        next.reserveCapacity(order.count)
        var trackerMap: [String: [String]] = [:]
        for hash in order {
            guard let torrent = torrents[hash] else { continue }
            let digest = torrent.info.hashValue
            next[hash] = digest
            if full || sentTorrents[hash] != digest { changed.append(torrent.info) }
            for tracker in torrent.trackers { trackerMap[tracker.url, default: []].append(hash) }
        }
        let removed = sentTorrents.keys.filter { next[$0] == nil }
        sentTorrents = next

        let changedCategories = categories.values.filter { full || sentCategories[$0.name] != $0 }
        let removedCategories = sentCategories.keys.filter { categories[$0] == nil }
        sentCategories = categories

        let addedTags = full ? Array(tags) : Array(tags.subtracting(sentTags))
        let removedTags = Array(sentTags.subtracting(tags))
        sentTags = tags

        let changedTrackers = trackerMap.filter { full || sentTrackers[$0.key] != $0.value }
            .map { TrackerTorrents(url: $0.key, hashes: $0.value) }
        let removedTrackers = sentTrackers.keys.filter { trackerMap[$0] == nil }
        sentTrackers = trackerMap

        return MainDataUpdate(
            rid: rid, fullUpdate: full, torrents: changed, torrentsRemoved: removed,
            categories: changedCategories, categoriesRemoved: removedCategories, tags: addedTags,
            tagsRemoved: removedTags, trackers: changedTrackers, trackersRemoved: removedTrackers,
            serverState: serverState()
        )
    }

    mutating func resetSync() {
        rid = 0
        sentTorrents = [:]
        sentCategories = [:]
        sentTags = []
        sentTrackers = [:]
    }

    func serverState() -> ServerState {
        var state = ServerState.blank
        var down: Int64 = 0
        var up: Int64 = 0
        var peers: Int64 = 0
        for torrent in torrents.values {
            down += torrent.info.dlSpeed
            up += torrent.info.upSpeed
            peers += torrent.info.connectionsCount
        }
        let limits = effectiveLimits()
        state.dlSpeed = down
        state.upSpeed = up
        state.dlSessionData = Int64(sessionDownload) + 3_418 * 1_048_576
        state.upSessionData = Int64(sessionUpload) + 1_207 * 1_048_576
        state.dlRateLimit = limits.down
        state.upRateLimit = limits.up
        state.dhtNodes = preferences.bittorrent.dht ? 342 : 0
        state.connectionStatus = .connected
        state.queueing = preferences.bittorrent.queueingEnabled
        state.useAltSpeedLimits = altSpeed
        state.useSubcategories = preferences.downloads.useSubcategories
        state.refreshInterval = preferences.advanced.refreshInterval
        state.freeSpaceOnDisk = Int64(412.6 * DemoFactory.gib)
        state.lastExternalAddressV4 = "203.0.113.42"
        state.lastExternalAddressV6 = "2001:db8:4b40::42"
        state.alltimeDownload = Int64(allTimeDownload)
        state.alltimeUpload = Int64(allTimeUpload)
        state.globalRatio = allTimeDownload > 0 ? allTimeUpload / allTimeDownload : 0
        state.totalPeerConnections = peers
        return state
    }

    func speedHistory(seconds: UInt32) -> [SpeedSample] {
        let end = animated ? Date.now.timeIntervalSince1970 : startTime + 1_800
        let count = Int(seconds)
        return (0..<count).map { offset in
            let time = end - Double(count - 1 - offset)
            let relative = time - startTime + 100_000
            let down = 2_600_000 * (0.35 + DemoRandom.wave(relative, seed: 7) + 0.4 * DemoRandom.wave(relative * 3.1, seed: 11))
            let up = 520_000 * (0.4 + DemoRandom.wave(relative * 0.8, seed: 13))
            let overhead = 0.03
            return SpeedSample(
                timestampMs: Int64(time * 1_000), upload: Int64(up * (1 + overhead)), download: Int64(down * (1 + overhead)),
                payloadUpload: Int64(up), payloadDownload: Int64(down),
                overheadUpload: Int64(up * overhead), overheadDownload: Int64(down * overhead),
                dhtUpload: 1_800 + Int64(DemoRandom.wave(relative, seed: 17) * 900),
                dhtDownload: 2_400 + Int64(DemoRandom.wave(relative, seed: 19) * 1_200),
                trackerUpload: 300, trackerDownload: 420
            )
        }
    }

    // MARK: Log and events

    mutating func appendLog(_ level: LogLevel, _ message: String) {
        let entry = LogMessage(
            id: Int64(log.count + 1), timestamp: Int64(Date.now.timeIntervalSince1970 * 1_000), level: level, message: message
        )
        log.append(entry)
        events.append(.log(message: entry))
    }

    mutating func takeEvents() -> [CoreEvent] {
        defer { events.removeAll() }
        return events
    }

    private mutating func appendInitialLog(now: Double) {
        appendLog(.normal, "qBittorrent Neo v0.1.1 started. Process ID: \(ProcessInfo.processInfo.processIdentifier)")
        appendLog(.normal, "Running in demo mode: sample data, no network activity.")
        appendLog(.info, "Trying to listen on the following list of IP addresses: \"0.0.0.0:51413,[::]:51413\"")
        appendLog(.info, "Successfully listening on IP. IP: \"0.0.0.0\". Port: \"TCP/51413\"")
        appendLog(.info, "DHT support [ON]")
        appendLog(.info, "Local Peer Discovery support [ON]")
        appendLog(.info, "Detected external IP. IP: \"203.0.113.42\"")
        appendLog(.warning, "Torrent errored. Torrent: \"The Pile (deduplicated) — shard 07\". Error: \"No space left on device\"")
        appendLog(.critical, "File error alert. Torrent: \"LibriVox — Collected Short Stories Vol. 3\". Reason: \"missing files\"")
        events.removeAll()
    }
}
