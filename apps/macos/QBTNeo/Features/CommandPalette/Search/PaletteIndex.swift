import Foundation

/// The palette's searchable rows, built when it opens (never per keystroke)
/// and dropped when it closes.
@MainActor
struct PaletteIndex {
    private(set) var commands: [PaletteCandidate] = []
    private(set) var torrents: [PaletteCandidate] = []
    private(set) var filters: [PaletteCandidate] = []
    /// Commands and filters by id (recent rows).
    private(set) var byID: [String: PaletteItem] = [:]

    init() {}

    init(app: AppModel) {
        let context = CommandContext(selectionOf: app)
        commands = Self.commands(in: context, targets: nil)
        torrents = app.transfers.items.map { Self.torrentCandidate($0) }
        filters = Self.filters(app)
        for candidate in commands + filters { byID[candidate.item.id] = candidate.item }
    }

    // MARK: Commands

    /// Registry commands that can run in `context`; `targets` nil means the selection.
    static func commands(in context: CommandContext, targets: [String]?) -> [PaletteCandidate] {
        CommandRegistry.all.filter { $0.canRun(in: context) && (targets == nil || $0.needsTargets) }.map { command in
            var item = PaletteItem(id: commandID(command.id, targets: targets), action: .command(command.id, targets: targets),
                                   title: command.title, symbol: command.symbol, shortcut: targets == nil ? command.shortcut : nil)
            item.isOn = command.isOn?(context.model)
            item.hasDetail = command.follow != nil
            if command.needsTargets, targets == nil { item.subtitle = selectionSubtitle(context) }
            return PaletteCandidate(item, keywords: command.keywords)
        }
    }

    static func commandID(_ id: CommandID, targets: [String]?) -> String {
        targets == nil ? "command:\(id.rawValue)" : "torrent-command:\(id.rawValue)"
    }

    /// "Sintel" or "3 torrents": what a selection command acts on.
    private static func selectionSubtitle(_ context: CommandContext) -> String {
        if context.ids.count == 1, let item = context.selection.items.first { return item.name }
        return String(localized: "\(context.ids.count) torrents", comment: "Command Palette: number of selected torrents a command acts on")
    }

    // MARK: Torrents

    static func torrentCandidate(_ torrent: TorrentItem) -> PaletteCandidate {
        var item = PaletteItem(id: "torrent:\(torrent.id)", action: .torrent(torrent.id), title: torrent.name,
                               symbol: torrent.state.systemImage)
        item.subtitle = "\(torrent.state.statusText) · \(ValueFormatter.percent(torrent.progress))"
        item.hasDetail = true
        return PaletteCandidate(item, keywords: torrent.category.isEmpty ? [] : [torrent.category])
    }

    // MARK: Filters

    private static func filters(_ app: AppModel) -> [PaletteCandidate] {
        let status = String(localized: "Status")
        let categories = String(localized: "Categories")
        let tags = String(localized: "Tags")
        let trackers = String(localized: "Trackers")
        var result: [PaletteCandidate] = StatusFilter.ordered.dropFirst().map { filter in
            filterCandidate("status:\(filter.index)", .status(filter), filter.title, filter.systemImage, status)
        }
        result.append(filterCandidate("uncategorized", .category(.uncategorized), String(localized: "Uncategorized"),
                                      Symbol.folderBadgeQuestionmark, categories))
        result += app.categories.sortedNames.map { name in
            filterCandidate("category:\(name)", .category(.category(name)), name, Symbol.folderFill, categories)
        }
        result.append(filterCandidate("untagged", .tag(.untagged), String(localized: "Untagged"), Symbol.tagSlash, tags))
        result += app.tags.sortedTags.map { tag in
            filterCandidate("tag:\(tag)", .tag(.tag(tag)), tag, Symbol.tagFill, tags)
        }
        result.append(filterCandidate("trackerless", .tracker(.trackerless), String(localized: "Trackerless"),
                                      Symbol.antennaRadiowavesLeftAndRightSlash, trackers))
        // Announce-status rows live in their own sidebar section when that option is on.
        let separate = app.gui.separateTrackerStatusFilter
        result.append(filterCandidate("tracker-error", separate ? .trackerStatus(.trackerError) : .tracker(.trackerError),
                                      String(localized: "Tracker error"), Symbol.xmarkOctagon, trackers))
        result.append(filterCandidate("other-error", separate ? .trackerStatus(.otherError) : .tracker(.otherError),
                                      String(localized: "Other error"), Symbol.xmarkOctagon, trackers))
        result.append(filterCandidate("warning", separate ? .trackerStatus(.warning) : .tracker(.warning),
                                      String(localized: "Warning"), Symbol.exclamationmarkTriangle, trackers))
        result += app.trackers.sortedHosts.map { host in
            filterCandidate("host:\(host)", .tracker(.host(host)), host, Symbol.serverRack, trackers)
        }
        return result
    }

    private static func filterCandidate(_ key: String, _ filter: SidebarItem, _ title: String, _ symbol: String,
                                        _ section: String) -> PaletteCandidate {
        var item = PaletteItem(id: "filter:\(key)", action: .filter(filter), title: title, symbol: symbol)
        item.subtitle = section
        return PaletteCandidate(item, keywords: [section])
    }

    // MARK: Nested lists

    /// "Show in List" and the commands that apply to one torrent.
    static func torrentActions(_ id: String, app: AppModel) -> [PaletteCandidate] {
        let reveal = PaletteItem(id: "torrent-reveal", action: .torrent(id),
                                 title: String(localized: "palette.showInList", defaultValue: "Show in Transfer List",
                                               comment: "Command Palette: select a torrent in the list"),
                                 symbol: Symbol.scope)
        return [PaletteCandidate(reveal)] + commands(in: CommandContext(model: app, ids: [id]), targets: [id])
    }

    /// New…, Reset, then every category (checked when all targets share it).
    static func categories(_ ids: [String], app: AppModel) -> [PaletteCandidate] {
        let shared = TorrentSelection(model: app, items: app.items(ids)).commonCategory
        var rows = [
            PaletteCandidate(PaletteItem(id: "category-new", action: .newCategory(targets: ids), title: String(localized: "New…"),
                                         symbol: Symbol.plus)),
            PaletteCandidate(PaletteItem(id: "category-reset", action: .category("", targets: ids), title: String(localized: "Reset"),
                                         symbol: Symbol.xmark)),
        ]
        rows += app.categories.sortedNames.map { name in
            var item = PaletteItem(id: "category:\(name)", action: .category(name, targets: ids), title: name, symbol: Symbol.folderFill)
            item.isOn = name == shared
            return PaletteCandidate(item)
        }
        return rows
    }

    /// Add…, Remove All, then every tag (checked when all targets have it; choosing toggles it).
    static func tags(_ ids: [String], app: AppModel) -> [PaletteCandidate] {
        let items = app.items(ids)
        var rows = [
            PaletteCandidate(PaletteItem(id: "tags-add", action: .addTags(targets: ids), title: String(localized: "Add…"), symbol: Symbol.plus)),
            PaletteCandidate(PaletteItem(id: "tags-remove-all", action: .removeAllTags(targets: ids), title: String(localized: "Remove All"),
                                         symbol: Symbol.xmark)),
        ]
        rows += app.tags.sortedTags.map { tag in
            var item = PaletteItem(id: "tag:\(tag)", action: .toggleTag(tag, targets: ids), title: tag, symbol: Symbol.tagFill)
            item.isOn = !items.isEmpty && items.allSatisfy { $0.tags.contains(tag) }
            return PaletteCandidate(item)
        }
        return rows
    }

    // MARK: Settings

    static func setting(_ result: SettingsSearch.Result) -> PaletteItem {
        var item = PaletteItem(id: "setting:\(result.spec.id)", action: .setting(result.spec.id), title: result.title,
                               symbol: result.spec.pane.symbol)
        item.subtitle = result.path
        return item
    }
}
