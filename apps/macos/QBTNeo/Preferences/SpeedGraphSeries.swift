import SwiftUI

/// Speed graph series (`GraphID`); upload series blue, download green.
enum SpeedGraphSeries: Int, CaseIterable, Identifiable, Sendable {
    case upload = 0
    case download = 1
    case payloadUpload = 2
    case payloadDownload = 3
    case overheadUpload = 4
    case overheadDownload = 5
    case dhtUpload = 6
    case dhtDownload = 7
    case trackerUpload = 8
    case trackerDownload = 9

    var id: Int { rawValue }

    static let defaultEnabled: Set<Self> = [.upload, .download]

    var title: String {
        switch self {
        case .upload: String(localized: "Total Upload")
        case .download: String(localized: "Total Download")
        case .payloadUpload: String(localized: "Payload Upload")
        case .payloadDownload: String(localized: "Payload Download")
        case .overheadUpload: String(localized: "Overhead Upload")
        case .overheadDownload: String(localized: "Overhead Download")
        case .dhtUpload: String(localized: "DHT Upload")
        case .dhtDownload: String(localized: "DHT Download")
        case .trackerUpload: String(localized: "Tracker Upload")
        case .trackerDownload: String(localized: "Tracker Download")
        }
    }

    var isUpload: Bool { rawValue.isMultiple(of: 2) }

    var color: Color { isUpload ? Design.Palette.upload : Design.Palette.download }

    /// qBittorrent pen styles: solid, dash, dash-dot, dash-dot-dot, dot.
    var dash: [CGFloat] {
        switch rawValue / 2 {
        case 0: []
        case 1: [6, 3]
        case 2: [6, 3, 1, 3]
        case 3: [6, 3, 1, 3, 1, 3]
        default: [1, 3]
        }
    }
}
