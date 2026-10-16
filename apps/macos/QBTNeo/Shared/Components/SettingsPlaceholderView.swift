import SwiftUI

/// Temporary Settings content until the Preferences window lands. Exposes the
/// main-window options already backed by `GUIPreferences`.
struct SettingsPlaceholderView: View {
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        Form {
            Section("Transfer List") {
                Toggle("Use alternating row colors", isOn: $gui.alternatingRowColors)
                Picker("Color by state:", selection: $gui.stateColorScope) {
                    ForEach(StateColorScope.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Hide zero and infinity values", isOn: $gui.hideZeroValues)
                Picker("Hide in", selection: $gui.hideZeroMode) {
                    ForEach(HideZeroMode.allCases) { Text($0.title).tag($0) }
                }
                .disabled(!gui.hideZeroValues)
                Picker("Double-click on downloading torrents", selection: $gui.doubleClickDownloading) {
                    ForEach(DoubleClickAction.menuOrder) { Text($0.title).tag($0) }
                }
                Picker("Double-click on completed torrents", selection: $gui.doubleClickCompleted) {
                    ForEach(DoubleClickAction.menuOrder) { Text($0.title).tag($0) }
                }
            }
            Section("Desktop") {
                Toggle("Show speed in Dock", isOn: $gui.showSpeedInDock)
                Toggle("Show qBittorrent Neo in menu bar", isOn: $gui.showMenuBarIcon)
                Toggle("Confirmation on exit when torrents are active", isOn: $gui.confirmOnExit)
                Toggle("Display notifications", isOn: $gui.notificationsEnabled)
                Toggle("Display notifications for added torrents", isOn: $gui.notifyTorrentAdded)
                Toggle("Show free disk space in status bar", isOn: $gui.statusBarFreeDiskSpace)
            }
            Section {
                Text("The complete Preferences window is coming soon.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }
}
