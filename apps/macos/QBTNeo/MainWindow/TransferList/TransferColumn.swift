import SwiftUI

/// Every transfer-list column (`TransferListModel::Column`, features.md §1.6.1).
/// The raw value is the stable customization ID persisted with the table state.
enum TransferColumn: String, CaseIterable, Codable, Sendable {
    case queuePosition = "queue"
    case name
    case size
    case totalSize
    case progress
    case status
    case seeds
    case peers
    case downSpeed
    case upSpeed
    case eta
    case ratio
    case popularity
    case category
    case tags
    case addedOn
    case completedOn
    case tracker
    case downLimit
    case upLimit
    case downloaded
    case uploaded
    case sessionDownloaded
    case sessionUploaded
    case remaining
    case timeActive
    case savePath
    case completed
    case ratioLimit
    case lastSeenComplete
    case lastActivity
    case availability
    case incompletePath
    case infohashV1
    case infohashV2
    case reannounceIn
    case isPrivate = "private"
    case createdOn

    var title: String {
        switch self {
        case .queuePosition: "#"
        case .name: String(localized: "Name")
        case .size: String(localized: "Size")
        case .totalSize: String(localized: "Total Size")
        case .progress: String(localized: "Progress")
        case .status: String(localized: "Status")
        case .seeds: String(localized: "Seeds")
        case .peers: String(localized: "Peers")
        case .downSpeed: String(localized: "Down Speed")
        case .upSpeed: String(localized: "Up Speed")
        case .eta: String(localized: "ETA")
        case .ratio: String(localized: "Ratio")
        case .popularity: String(localized: "Popularity")
        case .category: String(localized: "Category")
        case .tags: String(localized: "Tags")
        case .addedOn: String(localized: "Added On")
        case .completedOn: String(localized: "Completed On")
        case .tracker: String(localized: "Tracker")
        case .downLimit: String(localized: "Down Limit")
        case .upLimit: String(localized: "Up Limit")
        case .downloaded: String(localized: "Downloaded")
        case .uploaded: String(localized: "Uploaded")
        case .sessionDownloaded: String(localized: "Session Downloaded")
        case .sessionUploaded: String(localized: "Session Uploaded")
        case .remaining: String(localized: "Remaining")
        case .timeActive: String(localized: "Time Active")
        case .savePath: String(localized: "Save Path")
        case .completed: String(localized: "Completed")
        case .ratioLimit: String(localized: "Ratio Limit")
        case .lastSeenComplete: String(localized: "Last Seen Complete")
        case .lastActivity: String(localized: "Last Activity")
        case .availability: String(localized: "Availability")
        case .incompletePath: String(localized: "Incomplete Save Path")
        case .infohashV1: String(localized: "Info Hash v1")
        case .infohashV2: String(localized: "Info Hash v2")
        case .reannounceIn: String(localized: "Reannounce In")
        case .isPrivate: String(localized: "Private")
        case .createdOn: String(localized: "Created On")
        }
    }

    /// Columns shown when no saved table state exists.
    var isVisibleByDefault: Bool {
        switch self {
        case .queuePosition, .name, .size, .progress, .status, .seeds, .peers, .downSpeed, .upSpeed,
             .eta, .ratio, .category, .tags, .availability:
            true
        default:
            false
        }
    }

    var isNumeric: Bool {
        switch self {
        case .queuePosition, .size, .totalSize, .seeds, .peers, .downSpeed, .upSpeed, .eta, .ratio,
             .popularity, .downLimit, .upLimit, .downloaded, .uploaded, .sessionDownloaded,
             .sessionUploaded, .remaining, .completed, .ratioLimit, .lastActivity, .availability, .reannounceIn:
            true
        default:
            false
        }
    }

    var idealWidth: Double {
        switch self {
        case .queuePosition: 34
        case .name: 320
        case .progress: 120
        case .status: 110
        case .savePath, .incompletePath, .tracker: 220
        case .infohashV1, .infohashV2: 280
        case .category, .tags: 110
        case .addedOn, .completedOn, .lastSeenComplete, .createdOn: 130
        default: 84
        }
    }
}
