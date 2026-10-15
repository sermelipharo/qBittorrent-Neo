import SwiftUI

/// Sidebar status rows (features.md §1.5.1), in `TorrentFilter::Status` order.
extension StatusFilter: Identifiable {
    public var id: Int { index }

    static let ordered: [StatusFilter] = [
        .all, .downloading, .seeding, .completed, .running, .stopped, .active, .inactive,
        .stalled, .stalledUploading, .stalledDownloading, .checking, .moving, .errored,
    ]

    /// Row index persisted in `TransferListFilters/selectedFilterIndex`.
    var index: Int { Self.ordered.firstIndex(of: self) ?? 0 }

    init(index: Int) {
        self = Self.ordered.indices.contains(index) ? Self.ordered[index] : .all
    }

    var title: String {
        switch self {
        case .all: String(localized: "All")
        case .downloading: String(localized: "Downloading")
        case .seeding: String(localized: "Seeding")
        case .completed: String(localized: "Completed")
        case .running: String(localized: "Running")
        case .stopped: String(localized: "Stopped")
        case .active: String(localized: "Active")
        case .inactive: String(localized: "Inactive")
        case .stalled: String(localized: "Stalled")
        case .stalledUploading: String(localized: "Stalled Uploading")
        case .stalledDownloading: String(localized: "Stalled Downloading")
        case .checking: String(localized: "Checking")
        case .moving: String(localized: "Moving")
        case .errored: String(localized: "Errored")
        }
    }

    var systemImage: String {
        switch self {
        case .all: "line.3.horizontal.decrease.circle"
        case .downloading: "arrow.down.circle"
        case .seeding: "arrow.up.circle"
        case .completed: "checkmark.circle"
        case .running: "play.circle"
        case .stopped: "pause.circle"
        case .active: "bolt.circle"
        case .inactive: "moon.circle"
        case .stalled: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
        case .stalledUploading: "arrow.up.circle.dotted"
        case .stalledDownloading: "arrow.down.circle.dotted"
        case .checking: "arrow.trianglehead.2.clockwise.rotate.90"
        case .moving: "folder"
        case .errored: "exclamationmark.triangle"
        }
    }

    var tint: Color {
        switch self {
        case .downloading, .running, .checking, .moving: TorrentState.downloading.color
        case .seeding, .stalledUploading: TorrentState.uploading.color
        case .completed: TorrentState.stoppedUploading.color
        case .stopped, .inactive: TorrentState.stoppedDownloading.color
        case .errored: TorrentState.error.color
        case .stalledDownloading, .stalled: TorrentState.stalledDownloading.color
        case .all, .active: .accentColor
        }
    }

    /// Membership rule of `TorrentFilter::matchStatus`.
    func matches(state: TorrentState, dlSpeed: Int64, upSpeed: Int64) -> Bool {
        switch self {
        case .all: true
        case .downloading: state.isDownloading
        case .seeding: state.isUploading
        case .completed: state.isCompleted
        case .running: !state.isStopped
        case .stopped: state.isStopped
        case .active: dlSpeed > 0 || upSpeed > 0
        case .inactive: dlSpeed <= 0 && upSpeed <= 0
        case .stalled: state == .stalledUploading || state == .stalledDownloading
        case .stalledUploading: state == .stalledUploading
        case .stalledDownloading: state == .stalledDownloading
        case .checking: state.isChecking
        case .moving: state == .moving
        case .errored: state.isErrored
        }
    }
}
