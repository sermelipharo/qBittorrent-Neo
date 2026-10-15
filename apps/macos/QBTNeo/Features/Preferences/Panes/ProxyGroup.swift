import SwiftUI

/// Privacy › Proxy Server, with qBittorrent's per-type rules
/// (`adjustProxyOptions`): no fields for (None); no hostname lookup, RSS,
/// general purposes or authentication for SOCKS4. The fields appear only
/// once a proxy type is chosen.
struct ProxyGroup: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        let connection = model.draft.connection
        let isSOCKS4 = connection.proxyType == .socks4
        SettingsGroup(.proxy) {
            Picker(SettingsCatalog.title("proxy_type"), selection: $model.draft.connection.proxyType) {
                ForEach(PreferenceChoices.proxyTypes, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
            }
            .fixedSize()
            .setting("proxy_type")
            if connection.proxyType != .none {
                if isSOCKS4 {
                    InlineMessage(text: String(localized: "Some functions are unavailable with the chosen proxy type!"), style: .warning)
                }
                CommitTextField(title: SettingsCatalog.key("proxy_ip"), text: $model.draft.connection.proxyIp, prompt: "127.0.0.1", trims: true)
                    .setting("proxy_ip")
                SpinField(title: SettingsCatalog.key("proxy_port"), value: $model.draft.connection.proxyPort, range: 1...65_535)
                    .setting("proxy_port")
                Toggle(SettingsCatalog.title("proxy_hostname_lookup"), isOn: $model.draft.connection.proxyHostnameLookup)
                    .help("If checked, hostname lookups are done via the proxy")
                    .disabled(isSOCKS4)
                    .setting("proxy_hostname_lookup")
                Toggle(SettingsCatalog.title("proxy_auth_enabled"), isOn: $model.draft.connection.proxyAuthEnabled)
                    .disabled(isSOCKS4)
                    .setting("proxy_auth_enabled")
                if connection.proxyAuthEnabled, !isSOCKS4 {
                    CommitTextField(title: SettingsCatalog.key("proxy_username"), text: $model.draft.connection.proxyUsername, trims: true)
                        .setting("proxy_username")
                    CommitTextField(title: SettingsCatalog.key("proxy_password"), text: $model.draft.connection.proxyPassword,
                                    isSecure: true, trims: true)
                        .setting("proxy_password")
                    SettingFootnote(text: String(localized: "Note: The password is saved unencrypted"))
                }
                Toggle(SettingsCatalog.title("proxy_bittorrent"), isOn: $model.draft.connection.proxyBittorrent)
                    .setting("proxy_bittorrent")
                Toggle(SettingsCatalog.title("proxy_peer_connections"), isOn: $model.draft.connection.proxyPeerConnections)
                    .help("Otherwise, the proxy server is only used for tracker connections")
                    .disabled(!connection.proxyBittorrent)
                    .setting("proxy_peer_connections", indented: true)
                Toggle(SettingsCatalog.title("proxy_rss"), isOn: $model.draft.connection.proxyRss)
                    .help("RSS feeds will use proxy")
                    .disabled(isSOCKS4)
                    .setting("proxy_rss")
                Toggle(SettingsCatalog.title("proxy_misc"), isOn: $model.draft.connection.proxyMisc)
                    .help("Search engine, software updates or anything else will use proxy")
                    .disabled(isSOCKS4)
                    .setting("proxy_misc")
            }
        }
    }
}
