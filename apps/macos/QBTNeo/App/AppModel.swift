import AppKit
import Observation
import SwiftUI

/// Application state: owns the core client, the stores, the refresh loop and
/// the main window's presentation state. Views never call the core directly.
@Observable @MainActor
final class AppModel {
    enum Phase: Equatable {
        case starting
        case running
        case failed(String)
    }

    let launch: LaunchOptions
    let gui: GUIPreferences
    let transfers = TransferStore()
    let categories = CategoryStore()
    let tags = TagStore()
    /// Icons and colors of categories and tags (GUI-only).
    let labels: LabelAppearanceStore
    let trackers = TrackerStore()
    let status = SessionStatus()
    let log = LogStore()
    let list: TransferListModel
    let properties: PropertiesModel
    let lock = UILockModel()
    let favicons = TrackerFaviconStore()
    let palette: CommandPaletteModel

    private(set) var phase: Phase = .starting
    @ObservationIgnored private(set) var client: (any CoreClient)?
    /// The core's preferences (reloaded on `PreferencesChanged`).
    var corePreferences = Preferences.qbtDefaults

    // MARK: Main window presentation state
    var sheet: MainSheet?
    var alert: AppAlert?
    var confirmation: PendingConfirmation?
    var fileImport: FileImportRequest?
    /// A setting the Settings window should reveal when it appears (Command Palette).
    var pendingSettingReveal: String?
    var isMainWindowVisible = true {
        didSet { if isMainWindowVisible, !oldValue { restartRefreshLoop() } }
    }

    /// Open "Add new torrent" dialogs, keyed by their window value.
    private(set) var addDialogs: [UUID: AddTorrentModel] = [:]
    /// Set by the root views so models can open windows.
    @ObservationIgnored var openWindow: OpenWindowAction? {
        didSet { flushPendingWindows() }
    }
    @ObservationIgnored var pendingAddDialogs: [UUID] = []
    /// Set by the main window so models can open Settings.
    @ObservationIgnored var openSettings: OpenSettingsAction?

    /// The main window, once SwiftUI has created it.
    @ObservationIgnored weak var mainWindow: NSWindow?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var eventTask: Task<Void, Never>?
    @ObservationIgnored private var eventObservers: [UUID: AsyncStream<CoreEvent>.Continuation] = [:]
    @ObservationIgnored private let notifications = NotificationManager()
    @ObservationIgnored private var hasSynced = false

    init(launch: LaunchOptions = .current, gui: GUIPreferences = GUIPreferences()) {
        self.launch = launch
        self.gui = gui
        labels = LabelAppearanceStore(defaults: gui.defaults)
        list = TransferListModel(store: transfers, trackers: trackers, gui: gui)
        properties = PropertiesModel(patternFormat: gui.contentFilterPatternFormat)
        palette = CommandPaletteModel(persistent: !launch.isSnapshot)
        lock.clientProvider = { [weak self] in self?.client as? any AppInfoClient }
        favicons.clientProvider = { [weak self] in self?.client as? any AppInfoClient }
        palette.app = self
    }

    // MARK: Startup and shutdown

    /// Creates the core off the main thread (it loads the profile and
    /// restores torrents), then starts the refresh loop.
    func start() async {
        guard client == nil else { return }
        phase = .starting
        do {
            let client = try await Self.makeClient(launch)
            attach(client)
        } catch {
            phase = .failed(error.userMessage)
        }
    }

    /// Uses an already created client (previews, snapshots, tests).
    func attach(_ client: any CoreClient) {
        self.client = client
        let (stream, continuation) = AsyncStream<CoreEvent>.makeStream(bufferingPolicy: .bufferingNewest(1_000))
        client.setEventListener(listener: CoreEventBridge(continuation: continuation))
        eventTask = Task { [weak self] in
            for await event in stream {
                self?.handle(event)
            }
        }
        corePreferences = client.preferences()
        log.append(contentsOf: client.mainLog(lastKnownId: -1, levels: []))
        phase = .running
        restartRefreshLoop()
        if gui.notificationsEnabled, !launch.isSnapshot {
            Task { await notifications.requestAuthorization { [weak self] in self?.appendLocalLog($0) } }
        }
    }

    @concurrent
    private static func makeClient(_ launch: LaunchOptions) async throws -> any CoreClient {
        if launch.usesDemoData {
            return DemoClient(large: launch.demoLarge, animated: !launch.isSnapshot)
        }
        let config = AppConfig(profileDir: launch.profileDirectory, logToStderr: false, webuiPortOverride: 0, frontEnd: "macOS")
        return try QtCoreClient(config: config)
    }

    /// Saves resume data and stops the core (blocks up to ~10 s); call once.
    @concurrent
    static func shutdown(_ client: (any CoreClient)?) async {
        client?.shutdown()
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        eventTask?.cancel()
    }

    // MARK: Refresh loop

    /// (Re)starts the loop so the next tick happens immediately.
    func restartRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.refresh()
                let delay = self.isMainWindowVisible
                    ? Duration.milliseconds(max(self.corePreferences.advanced.refreshInterval, 30))
                    : Duration.seconds(5)
                try? await Task.sleep(for: delay)
            }
        }
    }

    /// One tick: transfer-list diff, then the visible properties tab. While
    /// the main window is hidden or occluded only the lightweight server
    /// state is polled (Dock badge, menu bar), and only if those are shown.
    func refresh() async {
        guard let client else { return }
        if isMainWindowVisible || !hasSynced || menuBarShowsCount {
            let update = await CoreCall.run { client.syncMainData() }
            hasSynced = true
            apply(update)
            await refreshProperties()
        } else if gui.showSpeedInDock || gui.showMenuBarIcon {
            let state = await CoreCall.run { client.serverState() }
            status.apply(state)
        }
    }

    /// The menu bar item shows torrent counts, which need the transfer list even while the window is hidden.
    private var menuBarShowsCount: Bool { gui.showMenuBarIcon && gui.menuBarContentMode.showsCount }

    func refreshProperties() async {
        guard let client else { return }
        properties.show(hash: list.currentID)
        guard gui.propertiesVisible else { return }
        await properties.refresh(tab: gui.propertiesTab, client: client, item: list.currentItem, period: gui.speedGraphPeriod)
    }

    private func apply(_ update: MainDataUpdate) {
        let changes = transfers.apply(torrents: update.torrents, removed: update.torrentsRemoved, fullUpdate: update.fullUpdate)
        categories.apply(changed: update.categories, removed: update.categoriesRemoved, fullUpdate: update.fullUpdate)
        tags.apply(added: update.tags, removed: update.tagsRemoved, fullUpdate: update.fullUpdate)
        // Removed elsewhere too (WebUI): their icons and colors go with them.
        if !update.categoriesRemoved.isEmpty { labels.removeCategories(update.categoriesRemoved) }
        if !update.tagsRemoved.isEmpty { labels.removeTags(update.tagsRemoved) }
        let trackersChanged = update.fullUpdate || !update.trackers.isEmpty || !update.trackersRemoved.isEmpty
        if trackersChanged {
            trackers.apply(changed: update.trackers, removed: update.trackersRemoved, fullUpdate: update.fullUpdate)
            list.trackersDidChange()
        } else {
            list.storeDidChange(changes)
        }
        status.apply(update.serverState)
        if menuBarShowsCount {
            let active = transfers.items.reduce(0) { $0 + ($1.dlSpeed > 0 || $1.upSpeed > 0 ? 1 : 0) }
            status.applyCounts(active: active, total: transfers.count)
        }
    }

    // MARK: Events

    private func handle(_ event: CoreEvent) {
        switch event {
        case .torrentAdded(_, let name):
            if gui.notificationsEnabled, gui.notifyTorrentAdded {
                notifications.post(title: String(localized: "Torrent added"), body: String(localized: "'\(name)' was added."))
            }
            refreshSoon()
        case .torrentFinished(_, let name):
            if gui.notificationsEnabled {
                notifications.post(title: String(localized: "Download completed"),
                                   body: String(localized: "'\(name)' has finished downloading."))
            }
        case .torrentError(_, let name, let message), .fullDiskError(_, let name, let message):
            if gui.notificationsEnabled {
                notifications.post(title: String(localized: "I/O Error"),
                                   body: String(localized: "An I/O error occurred for torrent '\(name)'.\n Reason: \(message)"))
            }
        case .addTorrentFailed(let source, let reason):
            if gui.notificationsEnabled {
                notifications.post(title: String(localized: "Add torrent failed"),
                                   body: String(localized: "Couldn't add torrent '\(source)', reason: \(reason)."))
            }
        case .log(let message):
            log.append(message)
        case .preferencesChanged:
            if let client { corePreferences = client.preferences() }
        case .shutdownRequested:
            NSApp.terminate(nil)
        case .allTorrentsFinished:
            handleAllTorrentsFinished()
        case .torrentRemoved, .torrentMetadataReceived:
            refreshSoon()
        default:
            break
        }
        for continuation in eventObservers.values { continuation.yield(event) }
    }

    /// Core events for other windows (RSS, Search, Creator, Log). The stream
    /// ends when the observing task is cancelled.
    func events() -> AsyncStream<CoreEvent> {
        let id = UUID()
        let (stream, continuation) = AsyncStream<CoreEvent>.makeStream(bufferingPolicy: .bufferingNewest(256))
        eventObservers[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.eventObservers[id] = nil }
        }
        return stream
    }

    /// "On Downloads Done" is handled by `CompletionActionController`
    /// (countdown confirmation, system actions) through `events()`.
    private func handleAllTorrentsFinished() {}

    func appendLocalLog(_ text: String, level: LogLevel = .warning) {
        let message = LogMessage(id: log.lastID + 1, timestamp: Int64(Date.now.timeIntervalSince1970 * 1_000), level: level, message: text)
        log.append(message)
    }

    /// Schedules a tick right away (after user actions).
    func refreshSoon() {
        guard phase == .running else { return }
        restartRefreshLoop()
    }

    // MARK: Add-torrent dialogs

    func register(_ dialog: AddTorrentModel) -> UUID {
        let id = UUID()
        addDialogs[id] = dialog
        return id
    }

    func addDialog(_ id: UUID) -> AddTorrentModel? { addDialogs[id] }

    func closeAddDialog(_ id: UUID) {
        addDialogs[id]?.cancel()
        addDialogs[id] = nil
    }

    // MARK: Derived values

    var windowTitle: String {
        let base = corePreferences.advanced.appInstanceName.isEmpty
            ? "qBittorrent Neo"
            : "qBittorrent Neo — \(corePreferences.advanced.appInstanceName)"
        guard gui.speedInTitleBar else { return base }
        return String(localized: "[D: \(UnitFormatter.speed(status.downloadRate)), U: \(UnitFormatter.speed(status.uploadRate))] \(base)")
    }

    var queueingEnabled: Bool { status.queueingEnabled }
}
