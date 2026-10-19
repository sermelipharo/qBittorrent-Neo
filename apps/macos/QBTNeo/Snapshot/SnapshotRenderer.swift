import AppKit
import SwiftUI

/// `--snapshot <dir>`: renders the main window in several states, the Add
/// Torrent dialog and the other dialogs to PNG files (light and dark) with
/// deterministic demo data, entirely off-screen, then the app exits.
@MainActor
struct SnapshotRenderer {
    let directory: URL
    let launch: LaunchOptions

    func run() async {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if FeatureSnapshots.isFiltered { return await FeatureSnapshots(directory: directory, launch: launch).run() }
        let suite = "mk.lex.qbtneo.snapshot"
        UserDefaults().removePersistentDomain(forName: suite)
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        let gui = GUIPreferences(defaults: defaults)
        gui.statusBarFreeDiskSpace = true
        gui.propertiesVisible = true
        let model = AppModel(launch: launch, gui: gui)
        let client = DemoClient(large: launch.demoLarge, animated: false)
        model.attach(client)
        await model.refresh()

        let focus = model.transfers.items.first { $0.name.hasPrefix("Sintel") } ?? model.transfers.items.first
        if let focus { model.list.selection = [focus.id] }
        await settle(model)

        for appearance in SnapshotAppearance.allCases {
            gui.propertiesTab = .general
            await settle(model)
            await renderMain(model, name: "main-general", appearance: appearance)
        }
        for tab in [PropertiesTab.trackers, .peers, .httpSources, .content, .speed] {
            gui.propertiesTab = tab
            await settle(model)
            await renderMain(model, name: "main-\(tab.snapshotName)", appearance: .light)
        }
        gui.propertiesTab = .content
        await settle(model)
        await renderMain(model, name: "main-content", appearance: .dark)

        // Filtered list with the panel collapsed.
        gui.propertiesVisible = false
        model.list.statusFilter = .downloading
        model.list.categoryFilter = .category("Linux ISOs")
        await settle(model)
        await renderMain(model, name: "main-filtered", appearance: .light)
        model.list.statusFilter = .all
        model.list.categoryFilter = .all
        gui.propertiesVisible = true
        if let focus { model.list.selection = [focus.id] }
        await settle(model)

        await render(UILockScreen().environment(model), size: Design.Window.snapshotSize, name: "lock-screen", appearance: .light)
        await SnapshotDialogs(renderer: self, model: model, client: client).renderAll()
        await FeatureSnapshots(directory: directory, launch: launch).run()
    }

    // MARK: Rendering

    func settle(_ model: AppModel) async {
        await model.refreshProperties()
        try? await Task.sleep(for: .milliseconds(150))
    }

    private func renderMain(_ model: AppModel, name: String, appearance: SnapshotAppearance) async {
        let view = MainWindow()
            .environment(model)
            .environment(model.gui)
        await render(view, size: Design.Window.snapshotSize, name: name, appearance: appearance)
    }

    /// Hosts `view` in an off-screen window of `size` (nil height = fitting
    /// height), captures the whole frame including the toolbar, writes a PNG.
    func render<V: View>(_ view: V, size: CGSize, name: String, appearance: SnapshotAppearance, fitHeight: Bool = false) async {
        let controller = NSHostingController(
            rootView: view.environment(\.isSnapshotRendering, true).modifier(SnapshotKeyAppearance(isActive: launch.snapshotActive))
        )
        controller.sceneBridgingOptions = [.toolbars, .title]
        let frame = CGRect(origin: CGPoint(x: -20_000, y: -20_000), size: size)
        let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        let window = launch.snapshotActive
            ? ActiveSnapshotWindow(contentRect: frame, styleMask: style, backing: .buffered, defer: false)
            : SnapshotWindow(contentRect: frame, styleMask: style, backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        if launch.snapshotClear {
            window.backgroundColor = .clear
            window.isOpaque = false
        }
        window.appearance = NSAppearance(named: appearance.name)
        window.contentViewController = controller
        window.setContentSize(size)
        window.orderFront(nil)
        try? await Task.sleep(for: .milliseconds(500))
        if fitHeight {
            let fitting = controller.view.fittingSize
            window.setContentSize(CGSize(width: size.width, height: max(fitting.height, 120)))
            try? await Task.sleep(for: .milliseconds(250))
        }
        window.displayIfNeeded()
        if let frameView = window.contentView?.superview, let rep = SnapshotBitmap.capture(frameView) {
            let url = directory.appending(path: "\(name)-\(appearance.rawValue).png")
            try? rep.representation(using: .png, properties: [:])?.write(to: url)
            print("snapshot: \(url.path(percentEncoded: false))")
        }
        window.orderOut(nil)
        window.close()
    }
}
