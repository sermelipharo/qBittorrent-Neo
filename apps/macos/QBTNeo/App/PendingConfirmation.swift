import Foundation

/// Yes/No questions asked before an action (features.md §3.34 and friends).
enum PendingConfirmation: Identifiable {
    case recheck(ids: [String])
    case enableAutoTMM(ids: [String])
    case removeAllTags(ids: [String])
    case banPeers(peers: [String])
    case removeTrackerFromAll(host: String)
    case mergeTrackers(hash: String, name: String, trackers: [TrackerTierEntry], urlSeeds: [String])
    case clearLockPassword

    var id: String {
        switch self {
        case .recheck(let ids): "recheck-\(ids.joined())"
        case .enableAutoTMM(let ids): "atm-\(ids.joined())"
        case .removeAllTags(let ids): "tags-\(ids.joined())"
        case .banPeers(let peers): "ban-\(peers.joined())"
        case .removeTrackerFromAll(let host): "tracker-\(host)"
        case .mergeTrackers(let hash, _, _, _): "merge-\(hash)"
        case .clearLockPassword: "clearLockPassword"
        }
    }

    var title: String {
        switch self {
        case .recheck: String(localized: "Recheck confirmation")
        case .enableAutoTMM: String(localized: "Enable automatic torrent management")
        case .removeAllTags: String(localized: "Remove All Tags")
        case .banPeers: String(localized: "Ban peer permanently")
        case .removeTrackerFromAll: String(localized: "Removal confirmation")
        case .mergeTrackers: String(localized: "Torrent is already present")
        case .clearLockPassword: String(localized: "Clear the password")
        }
    }

    var message: String {
        switch self {
        case .recheck:
            String(localized: "Are you sure you want to recheck the selected torrent(s)?")
        case .enableAutoTMM:
            String(localized: "Are you sure you want to enable Automatic Torrent Management for the selected torrent(s)? They may be relocated.")
        case .removeAllTags:
            String(localized: "Remove all tags from selected torrents?")
        case .banPeers:
            String(localized: "Are you sure you want to permanently ban the selected peers?")
        case .removeTrackerFromAll(let host):
            String(localized: "Are you sure you want to remove tracker \"\(host)\" from all torrents?")
        case .mergeTrackers(_, let name, _, _):
            String(localized: "Torrent '\(name)' is already in the transfer list. Do you want to merge trackers from new source?")
        case .clearLockPassword:
            String(localized: "Are you sure you want to clear the password?")
        }
    }

    var confirmTitle: String {
        switch self {
        case .recheck: String(localized: "Recheck")
        case .enableAutoTMM: String(localized: "Enable")
        case .removeAllTags: String(localized: "Remove All")
        case .banPeers: String(localized: "Ban")
        case .removeTrackerFromAll: String(localized: "Remove")
        case .mergeTrackers: String(localized: "Merge Trackers")
        case .clearLockPassword: String(localized: "Clear")
        }
    }

    var isDestructive: Bool {
        switch self {
        case .removeAllTags, .banPeers, .removeTrackerFromAll, .clearLockPassword: true
        default: false
        }
    }
}
