import SwiftUI

/// Connection › Proxy Server, with qBittorrent's per-type rules
/// (`adjustProxyOptions`): nothing for (None); no hostname lookup, RSS,
/// general purposes or authentication for SOCKS4.
struct ProxySection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        let type = model.draft.connection.proxyType
        let isNone = type == .none
        let isSOCKS4 = type == .socks4
        Section("Proxy Server") {
            Picker("Type:", selection: $model.draft.connection.proxyType) {
                ForEach(PreferenceChoices.proxyTypes, id: \.self) { value in
                    Text(PreferenceChoices.title(value)).tag(value)
                }
            }.settingAnchor("connection.18")
            if isSOCKS4 {
                InlineMessage(text: String(localized: "Some functions are unavailable with the chosen proxy type!"))
            }
            Group {
                CommitTextField(title: "Host:", text: $model.draft.connection.proxyIp, prompt: "127.0.0.1", trims: true)
                    .settingAnchor("connection.19")
                SpinField(title: "Port:", value: $model.draft.connection.proxyPort, range: 1...65_535).settingAnchor("connection.20")
            }
            .disabled(isNone)
            Toggle("Perform hostname lookup via proxy", isOn: $model.draft.connection.proxyHostnameLookup).settingAnchor("connection.21")
                .help("If checked, hostname lookups are done via the proxy")
                .disabled(isNone || isSOCKS4)
            Toggle("Authentication", isOn: $model.draft.connection.proxyAuthEnabled).settingAnchor("connection.22")
                .disabled(isNone || isSOCKS4)
            Group {
                CommitTextField(title: "Username:", text: $model.draft.connection.proxyUsername, trims: true).settingAnchor("connection.23")
                CommitTextField(title: "Password:", text: $model.draft.connection.proxyPassword, isSecure: true, trims: true)
                    .settingAnchor("connection.24")
                Text("Note: The password is saved unencrypted")
                    .settingsFootnote()
            }
            .disabled(isNone || isSOCKS4 || !model.draft.connection.proxyAuthEnabled)
            .padding(.leading, Design.Spacing.xLarge)
            Toggle("Use proxy for BitTorrent purposes", isOn: $model.draft.connection.proxyBittorrent).settingAnchor("connection.25")
                .disabled(isNone)
            Toggle("Use proxy for peer connections", isOn: $model.draft.connection.proxyPeerConnections).settingAnchor("connection.26")
                .help("Otherwise, the proxy server is only used for tracker connections")
                .disabled(isNone || !model.draft.connection.proxyBittorrent)
                .padding(.leading, Design.Spacing.xLarge)
            Toggle("Use proxy for RSS purposes", isOn: $model.draft.connection.proxyRss).settingAnchor("connection.27")
                .help("RSS feeds will use proxy")
                .disabled(isNone || isSOCKS4)
            Toggle("Use proxy for general purposes", isOn: $model.draft.connection.proxyMisc).settingAnchor("connection.28")
                .help("Search engine, software updates or anything else will use proxy")
                .disabled(isNone || isSOCKS4)
        }.settingAnchor("connection.17")
    }
}
