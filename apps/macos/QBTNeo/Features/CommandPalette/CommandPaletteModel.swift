import SwiftUI

/// State of the Command Palette (⌘K): the query, the visible sections, the
/// selected row, nested lists (a torrent's actions, category and tag
/// pickers) and running the chosen row. The search index is built when the
/// palette opens and released when it closes.
@Observable @MainActor
final class CommandPaletteModel {
    @ObservationIgnored weak var app: AppModel?

    private(set) var isPresented = false
    var query = "" {
        didSet { if query != oldValue { refresh(resetSelection: true) } }
    }
    private(set) var mode: PaletteMode = .root
    private(set) var sections: [PaletteResultSection] = []
    /// All rows in display order (↑/↓ and ⌘1…9 walk this list).
    private(set) var rows: [PaletteItem] = []
    private(set) var selectedID: String?

    @ObservationIgnored private var stack: [(mode: PaletteMode, query: String, selectedID: String?)] = []
    @ObservationIgnored private var index = PaletteIndex()
    @ObservationIgnored private var nestedCandidates: [PaletteCandidate] = []
    @ObservationIgnored private var recents: PaletteRecents
    @ObservationIgnored private var panel: CommandPalettePanelController?

    /// - Parameter persistent: false for snapshots (recent rows are neither read nor written).
    init(persistent: Bool = true) {
        recents = PaletteRecents(persistent: persistent)
    }

    // MARK: Presentation

    var canOpen: Bool {
        guard let app else { return false }
        return app.phase == .running && !app.lock.isLocked
    }

    func toggle() {
        if isPresented { close() } else { open() }
    }

    /// Builds the index and shows the panel over the main window with the search field focused.
    func open() {
        guard canOpen, !isPresented, let app else { return }
        prepare()
        isPresented = true
        let panel = panel ?? CommandPalettePanelController(model: self)
        self.panel = panel
        panel.show(over: app.mainWindow?.isVisible == true ? app.mainWindow : nil)
    }

    /// Resets to the root list for `query` without showing anything (also used by snapshots).
    func prepare(query: String = "") {
        guard let app else { return }
        index = PaletteIndex(app: app)
        stack = []
        nestedCandidates = []
        mode = .root
        replaceQuery(query)
        refresh(resetSelection: true)
    }

    func close() {
        guard isPresented else { return }
        isPresented = false
        panel?.hide()
        // Nothing of the session stays around while closed.
        index = PaletteIndex()
        nestedCandidates = []
        stack = []
        mode = .root
        replaceQuery("")
        sections = []
        rows = []
        selectedID = nil
    }

    /// Escape: leaves a nested list, otherwise closes.
    func cancel() {
        if !back() { close() }
    }

    // MARK: Nested lists

    /// Title of the nested list ("Sintel", "Category", "Tags"); nil at the root.
    var modeTitle: String? {
        switch mode {
        case .root: nil
        case .torrent(let id): app?.transfers.item(id)?.name ?? ""
        case .categories: String(localized: "Category")
        case .tags: String(localized: "Tags")
        }
    }

    var placeholder: String {
        switch mode {
        case .root:
            String(localized: "palette.placeholder", defaultValue: "Search actions, torrents, filters and settings",
                   comment: "Command Palette search field placeholder")
        case .torrent:
            String(localized: "palette.placeholder.actions", defaultValue: "Search actions",
                   comment: "Command Palette search field placeholder in a torrent's actions")
        case .categories, .tags:
            String(localized: "palette.placeholder.filter", defaultValue: "Filter",
                   comment: "Command Palette search field placeholder in the category or tag picker")
        }
    }

    var isNested: Bool { mode != .root }

    /// Tab / →: shows the selected row's nested list. Returns false when it has none.
    @discardableResult
    func drillIn() -> Bool {
        guard let app, let item = selectedItem, item.hasDetail else { return false }
        let next: PaletteMode
        switch item.action {
        case .torrent(let id) where mode == .root:
            next = .torrent(id)
        case .command(let id, let targets):
            let ids = targets ?? app.list.selectedIDs
            guard !ids.isEmpty, let follow = CommandRegistry[id].follow else { return false }
            next = follow == .categories ? .categories(ids) : .tags(ids)
        default:
            return false
        }
        stack.append((mode, query, selectedID))
        mode = next
        nestedCandidates = switch next {
        case .root: []
        case .torrent(let id): PaletteIndex.torrentActions(id, app: app)
        case .categories(let ids): PaletteIndex.categories(ids, app: app)
        case .tags(let ids): PaletteIndex.tags(ids, app: app)
        }
        replaceQuery("")
        refresh(resetSelection: true)
        return true
    }

    /// Shift-Tab, ←, ⌫ in an empty field, Escape: back to the previous list. Returns false at the root.
    @discardableResult
    func back() -> Bool {
        guard let previous = stack.popLast() else { return false }
        mode = previous.mode
        if mode == .root { nestedCandidates = [] }
        replaceQuery(previous.query)
        refresh(resetSelection: false, preferring: previous.selectedID)
        return true
    }

    // MARK: Selection

    var selectedItem: PaletteItem? {
        guard let selectedID else { return nil }
        return rows.first { $0.id == selectedID }
    }

    func select(_ id: String?) {
        guard selectedID != id else { return }
        selectedID = id
        announceSelection()
    }

    func moveSelection(by delta: Int) {
        guard !rows.isEmpty else { return }
        let current = rows.firstIndex { $0.id == selectedID } ?? -1
        let next = min(max(current + delta, 0), rows.count - 1)
        select(rows[next].id)
    }

    func selectFirst() { select(rows.first?.id) }
    func selectLast() { select(rows.last?.id) }

    // MARK: Running

    /// Return: runs the selected row (rows with a nested list that is not a torrent open it).
    func runSelected() {
        guard let item = selectedItem else { return }
        run(item)
    }

    /// ⌘1…⌘9: runs the n-th row.
    func run(number: Int) {
        guard rows.indices.contains(number - 1) else { return }
        select(rows[number - 1].id)
        runSelected()
    }

    func run(_ item: PaletteItem) {
        if case .command(let id, _) = item.action, CommandRegistry[id].follow != nil {
            select(item.id)
            drillIn()
            return
        }
        guard let app else { return }
        if mode == .root { recents.record(item.id) }
        let action = item.action
        close()
        // After the panel is gone, so sheets attach to the main window.
        Task { @MainActor in Self.perform(action, app: app) }
    }

    private static func perform(_ action: PaletteItem.Action, app: AppModel) {
        switch action {
        case .command(let id, let targets):
            let context = targets.map { CommandContext(model: app, ids: $0) } ?? CommandContext(selectionOf: app)
            let command = CommandRegistry[id]
            if command.canRun(in: context) { command.perform(context) }
        case .torrent(let id): app.revealTorrent(id)
        case .filter(let filter): app.applyFilter(filter)
        case .setting(let id): app.revealSetting(id)
        case .category(let name, let targets): app.setCategory(targets, name)
        case .newCategory(let targets): app.requestNewCategory(assignTo: targets)
        case .toggleTag(let tag, let targets): app.toggleTag(tag, for: targets)
        case .addTags(let targets): app.requestAddTags(targets)
        case .removeAllTags(let targets): app.requestRemoveAllTags(targets)
        }
    }

    // MARK: Results

    /// Sets the query without the `didSet` refresh; the caller refreshes once for the new list.
    private func replaceQuery(_ text: String) {
        guard query != text else { return }
        suppressRefresh = true
        query = text
        suppressRefresh = false
    }

    @ObservationIgnored private var suppressRefresh = false

    private func refresh(resetSelection: Bool, preferring preferred: String? = nil) {
        guard !suppressRefresh, let app else { return }
        switch mode {
        case .root:
            sections = PaletteSearch.root(query: query, index: index, recents: recents, app: app)
        case .torrent:
            sections = PaletteSearch.nested(nestedCandidates, section: .actions, query: query, recents: recents)
        case .categories:
            sections = PaletteSearch.nested(nestedCandidates, section: .categories, query: query, recents: recents)
        case .tags:
            sections = PaletteSearch.nested(nestedCandidates, section: .tags, query: query, recents: recents)
        }
        rows = sections.flatMap(\.items)
        if let preferred, rows.contains(where: { $0.id == preferred }) {
            select(preferred)
        } else if resetSelection || !rows.contains(where: { $0.id == selectedID }) {
            select(rows.first?.id)
        }
    }

    /// VoiceOver reads the newly selected row (focus stays in the search field).
    private func announceSelection() {
        guard isPresented, NSWorkspace.shared.isVoiceOverEnabled, let item = selectedItem else { return }
        let text = [item.title, item.subtitle].compactMap(\.self).joined(separator: ", ")
        AccessibilityNotification.Announcement(text).post()
    }
}
