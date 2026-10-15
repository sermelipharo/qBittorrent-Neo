import Foundation

/// One selectable sidebar row. The sidebar keeps exactly one selected row per
/// section; all section filters combine with AND (qBittorrent semantics).
enum SidebarItem: Hashable, Sendable {
    case status(StatusFilter)
    case category(CategoryFilter)
    case tag(TagFilter)
    case trackerStatus(TrackerStatusFilter)
    case tracker(TrackerFilter)

    enum Section: Hashable, Sendable {
        case status, category, tag, trackerStatus, tracker
    }

    var section: Section {
        switch self {
        case .status: .status
        case .category: .category
        case .tag: .tag
        case .trackerStatus: .trackerStatus
        case .tracker: .tracker
        }
    }
}
