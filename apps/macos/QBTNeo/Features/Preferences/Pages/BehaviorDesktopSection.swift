import SwiftUI

/// Behavior › Desktop and File association groups (macOS variants).
struct BehaviorDesktopSection: View {
    @Bindable var gui: GUIPreferences
    @Bindable var desktop: DesktopIntegrationModel

    var body: some View {
        Section("Desktop") {
            Toggle("Open qBittorrent Neo at login", isOn: $desktop.opensAtLogin)
            Picker("Window state on start up:", selection: $gui.startupWindowState) {
                ForEach(StartupWindowState.allCases) { state in
                    Text(state.title).tag(state)
                }
            }
            .help("qBittorrent Neo window state on start up")
            Toggle("Confirmation on exit when torrents are active", isOn: $gui.confirmOnExit)
                .help("Shows a confirmation dialog when exiting with active torrents")
            Toggle("Confirmation on auto-exit when downloads finish", isOn: $gui.confirmAutoExit)
            Toggle("Show speed in Dock", isOn: $gui.showSpeedInDock)
            Toggle("Show qBittorrent Neo in menu bar", isOn: $gui.showMenuBarIcon)
            Toggle("Check for program updates", isOn: $gui.checkForUpdates)
            LockPasswordRow()
        }

        Section {
            FileAssociationRow(title: "Use qBittorrent Neo for .torrent files", isSet: desktop.isTorrentHandler) {
                Task { await desktop.becomeTorrentHandler() }
            }
            FileAssociationRow(title: "Use qBittorrent Neo for magnet links", isSet: desktop.isMagnetHandler) {
                Task { await desktop.becomeMagnetHandler() }
            }
            if let error = desktop.errorMessage {
                InlineMessage(text: error)
            }
        } header: {
            Text("File association")
        } footer: {
            Text("Once set, the default application can be changed back in Finder's Get Info window.")
                .settingsFootnote()
        }
    }
}
