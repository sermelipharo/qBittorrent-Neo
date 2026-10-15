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
        }
        .defaultSize(Design.Window.mainDefaultSize)
        .defaultLaunchBehavior(model.launch.isSnapshot ? .suppressed : .presented)
        // AppDelegate ignores saved window state, so saving it is pure cost:
        // a restorable window makes AppKit snapshot its pixels after launch
        // into a window-sized malloc buffer (16 MB at 2x) that stays dirty.
        .restorationBehavior(.disabled)
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
            PreferencesWindow(navigator: model.launch.isSnapshot ? SettingsSnapshot.navigator : nil)
                .lockGated()
                .environment(model)
                .environment(model.gui)
        }
        // The window takes each pane's size (HIG: settings windows aren't resizable).
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)

        MenuBarExtra(isInserted: Bindable(model.gui).showMenuBarIcon) {
            MenuBarContent()
                .environment(model)
        } label: {
            MenuBarLabel(model: model)
        }
    }
}
