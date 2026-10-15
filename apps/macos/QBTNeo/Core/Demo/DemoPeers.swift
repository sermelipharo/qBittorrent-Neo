import Foundation

/// Deterministic peer lists with realistic clients, countries and flags.
enum DemoPeers {
    private static let countries: [(code: String, name: String)] = [
        ("US", "United States"), ("DE", "Germany"), ("NL", "Netherlands"), ("FR", "France"), ("GB", "United Kingdom"),
        ("CA", "Canada"), ("SE", "Sweden"), ("JP", "Japan"), ("BR", "Brazil"), ("PL", "Poland"), ("AU", "Australia"),
        ("FI", "Finland"), ("UA", "Ukraine"), ("KR", "South Korea"), ("IN", "India"), ("ES", "Spain"), ("IT", "Italy"),
        ("CH", "Switzerland"), ("NO", "Norway"), ("SG", "Singapore"), ("CZ", "Czechia"), ("RO", "Romania"),
    ]

    private static let clients: [(name: String, peerID: String)] = [
        ("qBittorrent 5.0.3", "-qB5030-"), ("qBittorrent 4.6.7", "-qB4670-"), ("Transmission 4.0.6", "-TR4060-"),
        ("Deluge 2.1.1", "-DE211s-"), ("libtorrent (Rasterbar) 2.0.10", "-LT20A0-"), ("µTorrent 3.6.0", "-UT360S-"),
        ("BitComet 2.10", "-BC0210-"), ("rqbit 8.0.0", "-rQ0800-"), ("Tixati 3.29", "TIX0329-"),
        ("aria2 1.37.0", "A2-1-37-"), ("BiglyBT 3.7.0.0", "-BI3700-"), ("Vuze 5.7.7.0", "-AZ5770-"),
    ]

    private static let flagDescriptions: [Character: String] = [
        "d": String(localized: "Interested (local) and choked (peer)"),
        "D": String(localized: "Interested (local) and unchoked (peer)"),
        "u": String(localized: "Interested (peer) and choked (local)"),
        "U": String(localized: "Interested (peer) and unchoked (local)"),
        "K": String(localized: "Not interested (local) and unchoked (peer)"),
        "?": String(localized: "Not interested (peer) and unchoked (local)"),
        "O": String(localized: "Optimistic unchoke"),
        "S": String(localized: "Peer snubbed"),
        "I": String(localized: "Incoming connection"),
        "H": String(localized: "Peer from DHT"),
        "X": String(localized: "Peer from PEX"),
        "L": String(localized: "Peer from LSD"),
        "E": String(localized: "Encrypted traffic"),
        "e": String(localized: "Encrypted handshake"),
        "P": "μTP",
        "h": String(localized: "Peer is using NAT hole punching"),
    ]

    private static let flagOrder: [Character] = ["d", "D", "u", "U", "K", "?", "O", "S", "I", "H", "X", "L", "E", "e", "P", "h"]

    static func peers(for torrent: DemoTorrent, time: Double) -> [PeerInfo] {
        let info = torrent.info
        guard torrent.isRunning, info.state != .checkingDownloading, info.state != .checkingUploading else { return [] }
        var random = DemoRandom(seed: torrent.seed)
        let downloading = info.progress < 1
        let count = max(Int(info.numSeeds + info.numLeechs), 0)
        let fileNames = torrent.files.map { ($0.name as NSString).lastPathComponent }
        let speedShare = 1 / Double(max(count, 1))

        return (0..<count).map { index in
            let isSeed = index < Int(info.numSeeds)
            let country = random.pick(countries)
            let client = random.pick(clients)
            let ipv6 = random.unit() < 0.18
            let ip = ipv6
                ? "2a0\(random.int(1...9)):\(hex(random.int(4_096...65_535))):\(hex(random.int(1...65_535)))::\(hex(random.int(1...255)))"
                : "\(random.int(23...223)).\(random.int(0...255)).\(random.int(0...255)).\(random.int(1...254))"
            let utp = random.unit() < 0.45
            var flags: Set<Character> = []
            if downloading && isSeed { flags.insert(random.unit() < 0.85 ? "D" : "d") }
            if !isSeed { flags.insert(random.unit() < 0.7 ? "U" : "u") }
            if downloading && !isSeed && random.unit() < 0.3 { flags.insert("K") }
            if random.unit() < 0.08 { flags.insert("O") }
            if random.unit() < 0.05 { flags.insert("S") }
            if random.unit() < 0.4 { flags.insert("I") }
            flags.insert(random.pick(["H", "X", "H", "L"]))
            if random.unit() < 0.6 { flags.insert("E") } else if random.unit() < 0.5 { flags.insert("e") }
            if utp { flags.insert("P") }
            let ordered = flagOrder.filter(flags.contains)

            let wave = DemoRandom.wave(time, seed: torrent.seed &+ UInt64(index))
            let down = downloading && isSeed ? Int64(torrent.baseDown * speedShare * 2 * wave) : 0
            let up = !isSeed ? Int64(torrent.baseUp * speedShare * 2 * (1 - wave)) : 0
            let peerProgress = isSeed ? 1 : random.unit()
            return PeerInfo(
                ip: ip, port: UInt16(random.int(1_025...65_000)), client: client.name, peerIdClient: client.peerID,
                connectionType: utp ? "μTP" : "BT", country: country.name, countryCode: country.code,
                dlSpeed: down, upSpeed: up,
                downloaded: Int64(Double(info.size) * random.unit() * 0.05),
                uploaded: Int64(Double(info.size) * random.unit() * 0.03),
                progress: peerProgress,
                relevance: isSeed ? 1 : (downloading ? random.unit() * 0.6 : 0),
                flags: ordered.map(String.init).joined(separator: " "),
                flagsDescription: ordered.map { "\($0) = \(flagDescriptions[$0] ?? "")" }.joined(separator: "\n"),
                files: down > 0 || up > 0 ? (fileNames.isEmpty ? "" : random.pick(fileNames)) : "",
                hostName: ""
            )
        }
    }

    private static func hex(_ value: Int) -> String { String(value, radix: 16) }

    /// DHT / PeX / LSD pseudo rows shown first in the Trackers tab.
    static func stickyTrackerRows(for torrent: DemoTorrent, dht: Bool, pex: Bool, lsd: Bool) -> [TrackerEntry] {
        let isPrivate = torrent.info.private ?? false
        func row(_ name: String, sessionEnabled: Bool, torrentDisabled: Bool) -> TrackerEntry {
            let status: TrackerStatus = sessionEnabled && !isPrivate && !torrentDisabled ? .working : .disabled
            return TrackerEntry(
                url: name, tier: -1, status: status, updating: false,
                message: isPrivate ? String(localized: "This torrent is private") : "",
                numPeers: -1, numSeeds: status == .working ? Int64(torrent.seed % 23) : 0,
                numLeeches: status == .working ? Int64(torrent.seed % 7) : 0, numDownloaded: -1,
                nextAnnounce: 0, minAnnounce: 0, endpoints: []
            )
        }
        return [
            row("** [DHT] **", sessionEnabled: dht, torrentDisabled: torrent.dhtDisabled),
            row("** [PeX] **", sessionEnabled: pex, torrentDisabled: torrent.pexDisabled),
            row("** [LSD] **", sessionEnabled: lsd, torrentDisabled: torrent.lsdDisabled),
        ]
    }
}
