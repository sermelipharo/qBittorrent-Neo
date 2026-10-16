import SwiftUI

/// Settings › Advanced: the "Show advanced settings" switch and, while it is
/// on, qBittorrent's and libtorrent's tuning rows with their own labels.
struct AdvancedPane: View {
    @Bindable var model: PreferencesModel
    @Environment(SettingsNavigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        SettingsPaneView(.advanced, model: model, groupedHeight: navigator.showsAdvanced ? SettingsLayout.maxPaneHeight : 112) {
            Section {
                Toggle(isOn: $navigator.showsAdvanced) {
                    Text(SettingsCatalog.title(SettingsNavigator.showAdvancedKey))
                    if let help = SettingsCatalog.help(SettingsNavigator.showAdvancedKey) {
                        Text(help)
                    }
                }
                .toggleStyle(.switch)
                .setting(SettingsNavigator.showAdvancedKey, help: false)
            } footer: {
                if navigator.showsAdvanced {
                    HStack(spacing: Design.Spacing.large) {
                        Link("qBittorrent options", destination: PreferenceLinks.advancedDocs)
                        Link("libtorrent settings", destination: PreferenceLinks.libtorrentDocs)
                    }
                    .font(.callout)
                }
            }
        } content: {
            AdvancedLogsGroups(model: model)
            AdvancedEngineGroups(model: model)
            AdvancedNetworkGroups(model: model)
            AdvancedLimitsGroups(model: model)
        }
    }
}
