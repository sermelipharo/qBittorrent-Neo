import Foundation

/// One row of the Trackers tab: a tracker, a sticky DHT/PeX/LSD row, or an
/// announce endpoint of an expanded tracker.
struct TrackerRow: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case sticky
        case tracker
        case endpoint(parentURL: String)
    }

    let id: String
    var kind: Kind
    var url: String
    var tier: Int64
    var btVersion: Int32
    var status: TrackerStatus
    var updating: Bool
    var message: String
    var peers: Int64
    var seeds: Int64
    var leeches: Int64
    var downloaded: Int64
    var nextAnnounce: Int64
    var minAnnounce: Int64
    var hasEndpoints: Bool

    init(entry: TrackerEntry) {
        let sticky = entry.tier < 0
        id = entry.url
        kind = sticky ? .sticky : .tracker
        url = entry.url
        tier = entry.tier
        btVersion = -1
        status = entry.status
        updating = entry.updating
        message = entry.message
        peers = entry.numPeers
        seeds = entry.numSeeds
        leeches = entry.numLeeches
        downloaded = entry.numDownloaded
        nextAnnounce = entry.nextAnnounce
        minAnnounce = entry.minAnnounce
        hasEndpoints = !entry.endpoints.isEmpty
    }

    init(endpoint: TrackerEndpoint, parent: TrackerEntry) {
        id = parent.url + "#" + endpoint.name + "#\(endpoint.btVersion)"
        kind = .endpoint(parentURL: parent.url)
        url = endpoint.name
        tier = -1
        btVersion = endpoint.btVersion
        status = endpoint.status
        updating = endpoint.updating
        message = endpoint.message
        peers = endpoint.numPeers
        seeds = endpoint.numSeeds
        leeches = endpoint.numLeeches
        downloaded = endpoint.numDownloaded
        nextAnnounce = endpoint.nextAnnounce
        minAnnounce = endpoint.minAnnounce
        hasEndpoints = false
    }

    var isRealTracker: Bool { kind == .tracker }

    var statusText: String {
        if updating { return String(localized: "Updating...") }
        if kind == .sticky {
            return status == .working ? String(localized: "Working") : String(localized: "Disabled")
        }
        return switch status {
        case .disabled: String(localized: "Disabled")
        case .notContacted: String(localized: "Not contacted yet")
        case .working: String(localized: "Working")
        case .updating: String(localized: "Updating...")
        case .notWorking: String(localized: "Not working")
        case .trackerError: String(localized: "Tracker error")
        case .unreachable: String(localized: "Unreachable")
        }
    }
}
