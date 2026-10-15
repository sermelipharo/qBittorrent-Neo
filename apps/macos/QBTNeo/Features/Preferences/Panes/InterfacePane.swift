import SwiftUI

/// Settings › Interface: what the torrent list, sidebar, details and status bar look like.
struct InterfacePane: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        SettingsPaneView(.interface, model: model) {
            SettingsGroup(.appearance) {
                Picker(SettingsCatalog.title("Appearance/ColorScheme"), selection: $gui.colorScheme) {
                    ForEach([ColorSchemePreference.system, .light, .dark]) { Text($0.title).tag($0) }
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                .setting("Appearance/ColorScheme")
            }

            SettingsGroup(.torrentList) {
                Toggle(SettingsCatalog.title("Preferences/General/AlternatingRowColors"), isOn: $gui.alternatingRowColors)
                    .setting("Preferences/General/AlternatingRowColors")
            } content: {
                Toggle(SettingsCatalog.title("GUI/TransferList/UseTorrentStatesColors"), isOn: $gui.useTorrentStatesColors)
                    .setting("GUI/TransferList/UseTorrentStatesColors")
                Toggle(SettingsCatalog.title("GUI/TransferList/ProgressBarFollowsTextColor"), isOn: $gui.progressBarFollowsTextColor)
                    .disabled(!gui.useTorrentStatesColors)
                    .setting("GUI/TransferList/ProgressBarFollowsTextColor", indented: true)
                HStack(spacing: Design.Spacing.regular) {
                    Toggle(SettingsCatalog.title("Preferences/General/HideZeroValues"), isOn: $gui.hideZeroValues)
                    Picker(SettingsCatalog.title("Preferences/General/HideZeroValues"), selection: $gui.hideZeroMode) {
                        ForEach(HideZeroMode.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(!gui.hideZeroValues)
                }
                .setting("Preferences/General/HideZeroValues")
            }

            SettingsGroup(.doubleClick) {
                Picker(SettingsCatalog.title("Preferences/Downloads/DblClOnTorDl"), selection: $gui.doubleClickDownloading) {
                    ForEach(DoubleClickAction.menuOrder) { Text($0.title).tag($0) }
                }
                .fixedSize()
                .setting("Preferences/Downloads/DblClOnTorDl")
                Picker(SettingsCatalog.title("Preferences/Downloads/DblClOnTorFn"), selection: $gui.doubleClickCompleted) {
                    ForEach(DoubleClickAction.menuOrder) { Text($0.title).tag($0) }
                }
                .fixedSize()
                .setting("Preferences/Downloads/DblClOnTorFn")
            }

            SettingsGroup(.sidebar) {
                Toggle(SettingsCatalog.title("TransferListFilters/HideZeroStatusFilters"), isOn: $gui.hideZeroStatusFilters)
                    .setting("TransferListFilters/HideZeroStatusFilters")
            } content: {
                Toggle(SettingsCatalog.title("TransferListFilters/SeparateTrackerStatusFilter"), isOn: $gui.separateTrackerStatusFilter)
                    .help("Use separate \"Tracker status\" filter. Otherwise it gets merged with \"Trackers\" filter.")
                    .setting("TransferListFilters/SeparateTrackerStatusFilter")
                Toggle(SettingsCatalog.title("GUI/DownloadTrackerFavicon"), isOn: $gui.downloadTrackerFavicon)
                    .setting("GUI/DownloadTrackerFavicon")
            }

            SettingsGroup(.torrentDetails) {
                Toggle(SettingsCatalog.title("SpeedWidget/Enabled"), isOn: $gui.speedGraphsEnabled)
                    .setting("SpeedWidget/Enabled")
            } content: {
                Toggle(SettingsCatalog.title("Preferences/General/TorrentContentDragEnabled"), isOn: $gui.torrentContentDragEnabled)
                    .help("Replaces multi-selection (hold Option key to invert)")
                    .setting("Preferences/General/TorrentContentDragEnabled")
            }

            SettingsGroup(.statusBar) {
                Toggle(SettingsCatalog.title("Preferences/General/StatusbarFreeDiskSpaceDisplayed"), isOn: $gui.statusBarFreeDiskSpace)
                    .setting("Preferences/General/StatusbarFreeDiskSpaceDisplayed")
            } content: {
                Toggle(SettingsCatalog.title("status_bar_external_ip"), isOn: $model.draft.behavior.statusBarExternalIp)
                    .setting("status_bar_external_ip")
            }

            SettingsGroup(.peersList) {
                Toggle(SettingsCatalog.title("resolve_peer_countries"), isOn: $model.draft.advanced.resolvePeerCountries)
                    .setting("resolve_peer_countries")
            } content: {
                Toggle(SettingsCatalog.title("resolve_peer_host_names"), isOn: $model.draft.advanced.resolvePeerHostNames)
                    .setting("resolve_peer_host_names")
            }

            SettingsGroup(.window) {
                SpinField(title: SettingsCatalog.key("refresh_interval"), value: $model.draft.advanced.refreshInterval, range: 30...99_999, unit: "ms")
                    .setting("refresh_interval")
                CommitTextField(title: SettingsCatalog.key("app_instance_name"), text: $model.draft.advanced.appInstanceName, trims: true)
                    .setting("app_instance_name")
            }
        }
    }
}
