import SwiftUI

@main
struct QBTNeoApp: SwiftUI.App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate

    var body: some Scene {
        let model = delegate.model
        Window(AppWindowID.main.title, id: AppWindowID.main.rawValue) {
            MainWindow()
                .environment(model)
                .environment(model.gui)
                .preferredColorScheme(model.gui.colorScheme.colorScheme)
        }
        .defaultSize(Design.Window.mainDefaultSize)
        .defaultLaunchBehavior(model.launch.isSnapshot ? .suppressed : .presented)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands(model: model)
        }

        WindowGroup(AppWindowID.addTorrent.title, id: AppWindowID.addTorrent.rawValue, for: UUID.self) { $id in
            AddTorrentWindow(dialogID: id)
                .lockGated()
                .environment(model)
                .environment(model.gui)
        }
        .defaultSize(Design.Window.addTorrentDefaultSize)
        .restorationBehavior(.disabled)
        .commandsRemoved()

        AuxiliaryWindows(model: model)

        Settings {
            PreferencesWindow()
                .lockGated()
                .environment(model)
                .environment(model.gui)
        }
        .defaultSize(FeatureDesign.Window.preferencesDefault)
        .windowResizability(.contentMinSize)

        MenuBarExtra(isInserted: Bindable(model.gui).showMenuBarIcon) {
            MenuBarContent()
                .environment(model)
        } label: {
            Label("qBittorrent Neo", systemImage: Symbol.arrowUpArrowDownCircle)
        }
    }
}
