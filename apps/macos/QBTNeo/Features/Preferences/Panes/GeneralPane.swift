import SwiftUI

/// Settings › General: how the app starts, quits, notifies and integrates with macOS.
struct GeneralPane: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui
    @State private var desktop = DesktopIntegrationModel()

    var body: some View {
        @Bindable var gui = gui
        SettingsPaneView(.general, model: model) {
            SettingsGroup(.startup) {
                Toggle(SettingsCatalog.title("system.openAtLogin"), isOn: $desktop.opensAtLogin)
                    .setting("system.openAtLogin")
            } content: {
                Picker(SettingsCatalog.title("GUI/StartUpWindowState"), selection: $gui.startupWindowState) {
                    ForEach(StartupWindowState.allCases) { Text($0.title).tag($0) }
                }
                .fixedSize()
                .setting("GUI/StartUpWindowState")
                Toggle(SettingsCatalog.title("BitTorrent/Session/StartPaused"), isOn: $model.draft.advanced.startPaused)
                    .setting("BitTorrent/Session/StartPaused")
            }

            SettingsGroup(.defaultApp) {
                FileAssociationRow(id: "system.torrentHandler", isSet: desktop.isTorrentHandler) {
                    Task { await desktop.becomeTorrentHandler() }
                }
                FileAssociationRow(id: "system.magnetHandler", isSet: desktop.isMagnetHandler) {
                    Task { await desktop.becomeMagnetHandler() }
                }
                if let error = desktop.errorMessage {
                    InlineMessage(text: error)
                }
            } footer: {
                SettingFootnote(text: String(localized: "Once set, the default application can be changed back in Finder's Get Info window."))
            }

            SettingsGroup(.dockMenuBar) {
                Toggle(SettingsCatalog.title("Preferences/Desktop/ShowSpeedInDock"), isOn: $gui.showSpeedInDock)
                    .setting("Preferences/Desktop/ShowSpeedInDock")
            } content: {
                Toggle(SettingsCatalog.title("Preferences/Desktop/ShowMacOSMenuBarIcon"), isOn: $gui.showMenuBarIcon)
                    .setting("Preferences/Desktop/ShowMacOSMenuBarIcon")
            }

            NotificationsGroup(model: model)

            SettingsGroup(.powerManagement) {
                Toggle(SettingsCatalog.title("Preferences/General/PreventFromSuspendWhenDownloading"), isOn: $gui.preventSuspendWhenDownloading)
                    .setting("Preferences/General/PreventFromSuspendWhenDownloading")
            } content: {
                Toggle(SettingsCatalog.title("Preferences/General/PreventFromSuspendWhenSeeding"), isOn: $gui.preventSuspendWhenSeeding)
                    .setting("Preferences/General/PreventFromSuspendWhenSeeding")
            }

            ConfirmationsGroup(model: model)

            SettingsGroup(.updates) {
                Toggle(SettingsCatalog.title("Preferences/Advanced/updateCheck"), isOn: $gui.checkForUpdates)
                    .setting("Preferences/Advanced/updateCheck")
            } content: {
                EmptyView()
            }

            SettingsGroup(.language) {
                Picker(SettingsCatalog.title("locale"), selection: $model.draft.behavior.locale) {
                    ForEach(LanguageChoice.choices(including: model.draft.behavior.locale)) { Text($0.title).tag($0.code) }
                }
                .fixedSize()
                .setting("locale")
            }
        }
        .task { desktop.refresh() }
    }
}
