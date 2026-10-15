import Foundation

/// Per-row counts shown in the sidebar, recomputed in one pass per refresh.
struct SidebarCounts: Equatable {
    var total = 0
    var status: [StatusFilter: Int] = [:]
    /// Category → torrents in it or in any subcategory.
    var categories: [String: Int] = [:]
    var uncategorized = 0
    var tags: [String: Int] = [:]
    var untagged = 0
    var trackerless = 0
    var trackerError = 0
    var otherError = 0
    var warning = 0
    var hosts: [String: Int] = [:]

    func count(for status: StatusFilter) -> Int {
        status == .all ? total : self.status[status, default: 0]
    }
}
