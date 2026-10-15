import SwiftUI

/// Status text, icon and color of each torrent state (features.md §1.7).
/// Colors are qBittorrent's GitHub Primer defaults (light / dark).
extension TorrentState {
    var statusText: String {
        switch self {
        case .unknown: ""
        case .forcedDownloading: String(localized: "[F] Downloading")
        case .downloading: String(localized: "Downloading")
        case .forcedDownloadingMetadata: String(localized: "[F] Downloading metadata")
        case .downloadingMetadata: String(localized: "Downloading metadata")
        case .stalledDownloading: String(localized: "Stalled")
        case .forcedUploading: String(localized: "[F] Seeding")
        case .uploading, .stalledUploading: String(localized: "Seeding")
        case .checkingResumeData: String(localized: "Checking resume data")
        case .queuedDownloading, .queuedUploading: String(localized: "Queued")
        case .checkingUploading, .checkingDownloading: String(localized: "Checking")
        case .stoppedDownloading: String(localized: "Stopped")
        case .stoppedUploading: String(localized: "Completed")
        case .moving: String(localized: "Moving")
        case .missingFiles: String(localized: "Missing Files")
        case .error: String(localized: "Errored")
        }
    }

    var systemImage: String {
        switch self {
        case .unknown, .missingFiles, .error: "exclamationmark.triangle.fill"
        case .forcedDownloading, .downloading: "arrow.down.circle.fill"
        case .forcedDownloadingMetadata, .downloadingMetadata: "arrow.down.circle.dotted"
        case .stalledDownloading: "arrow.down.circle"
        case .forcedUploading, .uploading: "arrow.up.circle.fill"
        case .stalledUploading: "arrow.up.circle"
        case .checkingResumeData, .checkingUploading, .checkingDownloading: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill"
        case .queuedDownloading, .queuedUploading: "clock.fill"
        case .stoppedDownloading: "pause.circle.fill"
        case .stoppedUploading: "checkmark.circle.fill"
        case .moving: "folder.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .unknown: .secondary
        case .forcedDownloading, .downloading, .forcedDownloadingMetadata, .downloadingMetadata,
             .checkingResumeData, .checkingUploading, .checkingDownloading, .moving:
            Self.green
        case .stalledDownloading: Self.stalledGreen
        case .forcedUploading, .uploading: Self.blue
        case .stalledUploading: Self.stalledBlue
        case .queuedDownloading, .queuedUploading: Self.brown
        case .stoppedDownloading: Self.gray
        case .stoppedUploading: Self.purple
        case .missingFiles, .error: Self.red
        }
    }

    private static let green = Color(light: 0x1A7F37, dark: 0x3FB950)
    private static let stalledGreen = Color(light: 0x2DA44E, dark: 0x238636)
    private static let blue = Color(light: 0x0969DA, dark: 0x58A6FF)
    private static let stalledBlue = Color(light: 0x0969DA, dark: 0x1F6FEB)
    private static let brown = Color(light: 0x7D4E00, dark: 0xA0700F)
    private static let gray = Color(light: 0x57606A, dark: 0x8B949E)
    private static let purple = Color(light: 0x8250DF, dark: 0xA371F7)
    private static let red = Color(light: 0xCF222E, dark: 0xF85149)

    // MARK: Classification (TorrentFilter::matchStatus)

    var isDownloading: Bool {
        switch self {
        case .downloading, .downloadingMetadata, .forcedDownloadingMetadata, .stalledDownloading,
             .checkingDownloading, .stoppedDownloading, .queuedDownloading, .forcedDownloading:
            true
        default:
            false
        }
    }

    var isUploading: Bool {
        switch self {
        case .uploading, .stalledUploading, .checkingUploading, .queuedUploading, .forcedUploading: true
        default: false
        }
    }

    var isCompleted: Bool {
        isUploading || self == .stoppedUploading
    }

    var isStopped: Bool { self == .stoppedDownloading || self == .stoppedUploading }
    var isQueued: Bool { self == .queuedDownloading || self == .queuedUploading }
    var isChecking: Bool { self == .checkingDownloading || self == .checkingUploading || self == .checkingResumeData }
    var isErrored: Bool { self == .error || self == .missingFiles }
    var isForced: Bool {
        self == .forcedDownloading || self == .forcedUploading || self == .forcedDownloadingMetadata
    }

    /// The progress bar is drawn disabled for these states.
    var dimsProgressBar: Bool { self == .error || self == .stoppedDownloading || self == .unknown }
}
