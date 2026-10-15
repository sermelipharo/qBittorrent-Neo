import SwiftUI

/// Menu bar status item menu: current speeds plus quick actions.
struct MenuBarContent: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if model.lock.isLocked {
            Text("qBittorrent Neo is locked")
            Divider()
            Button("Unlock…", action: model.showUnlockPrompt)
            Divider()
            // Goes through the delegate, which asks for the lock password.
            Button("Quit qBittorrent Neo") { NSApp.terminate(nil) }
        } else {
            unlockedContent
        }
    }

    @ViewBuilder private var unlockedContent: some View {
        Text("↓ \(UnitFormatter.speed(model.status.downloadRate)) · ↑ \(UnitFormatter.speed(model.status.uploadRate))")
        Divider()
        Button("Show qBittorrent Neo", action: showMainWindow)
        Button("Add Torrent File…") {
            showMainWindow()
            model.fileImport = .torrentFiles
        }
        Button("Add Torrent Link…") {
            showMainWindow()
            model.sheet = .addLinks(initialText: AppModel.clipboardLinks())
        }
        Divider()
        Toggle("Alternative Speed Limits", isOn: Bindable(model).alternativeSpeedLimits)
        Button("Set Global Speed Limits…") {
            showMainWindow()
            model.sheet = .speedLimits
        }
        Divider()
        Button("Start All Torrents", action: model.startAll)
        Button("Stop All Torrents", action: model.stopAll)
        Divider()
        Button("Quit qBittorrent Neo") { NSApp.terminate(nil) }
    }

    private func showMainWindow() {
        if model.openWindow == nil { model.openWindow = openWindow }
        openWindow(id: AppWindowID.main.rawValue)
        NSApp.activate()
    }
}
