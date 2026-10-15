import AppKit
import Observation

/// Filtering, sorting and selection of the transfer list, plus the sidebar
/// counts. Work happens here when data or criteria change, never in `body`:
/// `visibleItems` is only reassigned when the visible order actually changes.
@Observable @MainActor
final class TransferListModel {
    @ObservationIgnored private let store: TransferStore
    @ObservationIgnored private let trackers: TrackerStore
    @ObservationIgnored private let gui: GUIPreferences

    // MARK: Filters

    var statusFilter: StatusFilter {
        didSet {
            gui.selectedStatusFilterIndex = statusFilter.index
            refilter()
        }
    }
    var categoryFilter: CategoryFilter = .all { didSet { refilter() } }
    var tagFilter: TagFilter = .all { didSet { refilter() } }
    var trackerFilter: TrackerFilter = .all { didSet { refilter() } }
    var trackerStatusFilter: TrackerStatusFilter = .all { didSet { refilter() } }
    var searchText = "" { didSet { scheduleSearch() } }
    var searchScope: TransferSearchScope = .name { didSet { refilter() } }

    var sortOrder: [TransferSort] {
        didSet {
            persistSortOrder()
            resort()
        }
    }

    var selection: Set<String> = [] { didSet { updateCurrent() } }

    /// The torrent shown in the properties panel.
    private(set) var currentID: String?
    private(set) var visibleItems: [TorrentItem] = []
    private(set) var counts = SidebarCounts()

    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var matcher: TextMatcher?

    init(store: TransferStore, trackers: TrackerStore, gui: GUIPreferences) {
        self.store = store
        self.trackers = trackers
        self.gui = gui
        statusFilter = StatusFilter(index: gui.selectedStatusFilterIndex)
        sortOrder = Self.loadSortOrder()
    }

    // MARK: Sidebar selection

    /// Highlighted sidebar rows (bound to the sidebar `List`): the status row
    /// plus every section whose filter is active.
    var sidebarSelection: Set<SidebarItem> {
        get {
            var rows: Set<SidebarItem> = [.status(statusFilter)]
            if categoryFilter != .all { rows.insert(.category(categoryFilter)) }
            if tagFilter != .all { rows.insert(.tag(tagFilter)) }
            if trackerStatusFilter != .all { rows.insert(.trackerStatus(trackerStatusFilter)) }
            if trackerFilter != .all { rows.insert(.tracker(trackerFilter)) }
            return rows
        }
        set {
            let old = sidebarSelection
            let added = newValue.subtracting(old)
            let removed = old.subtracting(newValue)
            if NSEvent.modifierFlags.contains(.command) {
                // ⌘-click toggles one row: deselecting resets that section to "All".
                for item in added { select(item) }
                for item in removed where !added.contains(where: { $0.section == item.section }) {
                    reset(item.section)
                }
            } else if newValue.count == 1, let item = newValue.first {
                // Plain click or arrow key: change that section only.
                select(item)
            } else {
                for item in added { select(item) }
            }
        }
    }

    private func reset(_ section: SidebarItem.Section) {
        switch section {
        case .status: statusFilter = .all
        case .category: categoryFilter = .all
        case .tag: tagFilter = .all
        case .trackerStatus: trackerStatusFilter = .all
        case .tracker: trackerFilter = .all
        }
    }

    func select(_ item: SidebarItem) {
        switch item {
        case .status(let value): if statusFilter != value { statusFilter = value }
        case .category(let value): if categoryFilter != value { categoryFilter = value }
        case .tag(let value): if tagFilter != value { tagFilter = value }
        case .trackerStatus(let value): if trackerStatusFilter != value { trackerStatusFilter = value }
        case .tracker(let value): if trackerFilter != value { trackerFilter = value }
        }
    }

    /// Resets every sidebar filter (used when the sidebar is hidden).
    func resetSidebarFilters() {
        categoryFilter = .all
        tagFilter = .all
        trackerFilter = .all
        trackerStatusFilter = .all
    }

    /// Whether any filter (sidebar or text) hides torrents.
    var isFiltering: Bool {
        statusFilter != .all || categoryFilter != .all || tagFilter != .all || trackerFilter != .all
            || trackerStatusFilter != .all || !searchText.isEmpty
    }

    /// Shows every torrent: resets the sidebar filters and the filter text, applied immediately.
    func resetAllFilters() {
        statusFilter = .all
        resetSidebarFilters()
        searchText = ""
        searchTask?.cancel()
        rebuildMatcher()
        refilter()
    }

    // MARK: Updates

    /// Called after each sync with the store's changes.
    func storeDidChange(_ changes: TransferStore.ApplyResult) {
        guard !changes.isEmpty else { return }
        recount()
        refilter()
    }

    /// Called when tracker membership changed (affects host filters and counts).
    func trackersDidChange() {
        recount()
        refilter()
    }

    /// Selected items in visible order.
    var selectedItems: [TorrentItem] {
        guard !selection.isEmpty else { return [] }
        if selection.count == 1, let id = selection.first, let item = store.item(id) { return [item] }
        return visibleItems.filter { selection.contains($0.id) }
    }

    var selectedIDs: [String] { selectedItems.map(\.id) }

    var currentItem: TorrentItem? { currentID.flatMap(store.item) }

    // MARK: Filtering

    func refilter() {
        let filtered = store.items.filter(matches)
        apply(sorted(filtered))
    }

    private func resort() {
        apply(sorted(visibleItems))
    }

    private func apply(_ items: [TorrentItem]) {
        let changed = items.count != visibleItems.count || zip(items, visibleItems).contains { $0 !== $1 }
        if changed { visibleItems = items }
        // Drop selected rows that are no longer visible.
        if !selection.isEmpty {
            let visibleIDs = Set(items.map(\.id))
            let kept = selection.intersection(visibleIDs)
            if kept != selection { selection = kept }
        }
        updateCurrent()
    }

    private func matches(_ item: TorrentItem) -> Bool {
        guard statusFilter.matches(state: item.state, dlSpeed: item.dlSpeed, upSpeed: item.upSpeed),
              categoryFilter.matches(item.category),
              tagFilter.matches(item.tags),
              matchesTracker(item),
              matchesTrackerStatus(item)
        else { return false }
        guard let matcher else { return true }
        return matcher.matches(searchScope == .name ? item.name : item.savePath)
    }

    private func matchesTracker(_ item: TorrentItem) -> Bool {
        switch trackerFilter {
        case .all: true
        case .trackerless: item.trackersCount == 0
        case .trackerError: item.hasTrackerError
        case .otherError: item.hasOtherAnnounceError
        case .warning: item.hasTrackerWarning
        case .host(let host): trackers.hostTorrents[host]?.contains(item.id) ?? false
        }
    }

    private func matchesTrackerStatus(_ item: TorrentItem) -> Bool {
        guard gui.separateTrackerStatusFilter else { return true }
        return switch trackerStatusFilter {
        case .all: true
        case .warning: item.hasTrackerWarning
        case .trackerError: item.hasTrackerError
        case .otherError: item.hasOtherAnnounceError
        }
    }

    private func sorted(_ items: [TorrentItem]) -> [TorrentItem] {
        let order = sortOrder.isEmpty ? [TransferSort(.name)] : sortOrder
        return items.sorted { lhs, rhs in
            for comparator in order {
                var result = TransferSort.compareAscending(comparator.column, lhs, rhs)
                if comparator.order == .reverse { result = result.reversed }
                if result != .orderedSame { return result == .orderedAscending }
            }
            return lhs.id < rhs.id
        }
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled, let self else { return }
            self.rebuildMatcher()
            self.refilter()
        }
    }

    private func rebuildMatcher() {
        let pattern = searchText.trimmingCharacters(in: .whitespaces)
        if pattern.isEmpty {
            matcher = nil
        } else if gui.useRegexFilter {
            matcher = TextMatcher(regex: pattern) ?? TextMatcher(substring: pattern)
        } else if pattern.contains("*") || pattern.contains("?") {
            matcher = FilterPatternFormat.wildcards.matcher(for: pattern)
        } else {
            matcher = TextMatcher(substring: pattern)
        }
    }

    // MARK: Counts

    private func recount() {
        var next = SidebarCounts()
        next.total = store.count
        for item in store.items {
            for status in StatusFilter.ordered.dropFirst()
            where status.matches(state: item.state, dlSpeed: item.dlSpeed, upSpeed: item.upSpeed) {
                next.status[status, default: 0] += 1
            }
            if item.category.isEmpty {
                next.uncategorized += 1
            } else {
                next.categories[item.category, default: 0] += 1
                for ancestor in CategoryStore.ancestors(of: item.category) {
                    next.categories[ancestor, default: 0] += 1
                }
            }
            if item.tags.isEmpty {
                next.untagged += 1
            } else {
                for tag in item.tags { next.tags[tag, default: 0] += 1 }
            }
            if item.trackersCount == 0 { next.trackerless += 1 }
            if item.hasTrackerError { next.trackerError += 1 }
            if item.hasOtherAnnounceError { next.otherError += 1 }
            if item.hasTrackerWarning { next.warning += 1 }
        }
        for (host, ids) in trackers.hostTorrents { next.hosts[host] = ids.count }
        if next != counts { counts = next }
    }

    // MARK: Current torrent

    private func updateCurrent() {
        let next: String?
        if let currentID, selection.contains(currentID) {
            next = currentID
        } else if selection.count == 1 {
            next = selection.first
        } else if selection.isEmpty {
            next = nil
        } else {
            next = visibleItems.first { selection.contains($0.id) }?.id
        }
        if next != currentID { currentID = next }
    }

    // MARK: Persistence

    private static let sortKey = GUIPreferenceKey.transferListSortOrder.rawValue

    private static func loadSortOrder() -> [TransferSort] {
        guard let data = UserDefaults.standard.data(forKey: sortKey),
              let order = try? JSONDecoder().decode([TransferSort].self, from: data),
              !order.isEmpty
        else { return [TransferSort(.name)] }
        return order
    }

    private func persistSortOrder() {
        // Keep the primary and the previous (secondary) sort column, like qBittorrent.
        let trimmed = Array(sortOrder.prefix(2))
        if let data = try? JSONEncoder().encode(trimmed) {
            UserDefaults.standard.set(data, forKey: Self.sortKey)
        }
    }
}
