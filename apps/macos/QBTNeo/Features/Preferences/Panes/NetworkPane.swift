import SwiftUI

/// Settings › Network: whether peers can reach me, and how I find them.
struct NetworkPane: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        let connection = model.draft.connection
        SettingsPaneView(.network, model: model) {
            ConnectionStatusGroup(model: model)

            SettingsGroup(.listeningPort) {
                LabeledContent(SettingsCatalog.key("listen_port")) {
                    HStack(spacing: Design.Spacing.small) {
                        SpinControl(title: SettingsCatalog.key("listen_port"), value: $model.draft.connection.listenPort,
                                    range: 0...65_535, special: .text(String(localized: "Any")))
                            .help("Set to 0 to let your system pick an unused port")
                        Button("Random") { model.draft.connection.listenPort = Int64.random(in: 1_024...65_535) }
                    }
                }
                .setting("listen_port")
                Toggle(SettingsCatalog.title("upnp"), isOn: $model.draft.connection.upnp)
                    .setting("upnp")
            }

            SettingsGroup(.findingPeers) {
                Toggle(SettingsCatalog.title("dht"), isOn: $model.draft.bittorrent.dht)
                    .help("Find peers on the DHT network")
                    .setting("dht")
            } content: {
                Toggle(SettingsCatalog.title("pex"), isOn: $model.draft.bittorrent.pex)
                    .help("Exchange peers with compatible Bittorrent clients (µTorrent, Vuze, ...)")
                    .setting("pex")
                Toggle(SettingsCatalog.title("lsd"), isOn: $model.draft.bittorrent.lsd)
                    .help("Look for peers on your local network")
                    .setting("lsd")
            } footer: {
                SettingFootnote(text: String(localized: "Private torrents never use these."))
            }

            SettingsGroup(.protocolLimits) {
                Picker(SettingsCatalog.title("bittorrent_protocol"), selection: $model.draft.connection.bittorrentProtocol) {
                    ForEach(PreferenceChoices.protocols, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
                }
                .fixedSize()
                .setting("bittorrent_protocol")
                limitRow("max_connec", isOn: $model.maxConnectionsEnabled, value: $model.maxConnections, minimum: 2)
                limitRow("max_connec_per_torrent", isOn: $model.maxConnectionsPerTorrentEnabled, value: $model.maxConnectionsPerTorrent, minimum: 2)
                limitRow("max_uploads", isOn: $model.maxUploadsEnabled, value: $model.maxUploads, minimum: 1)
                limitRow("max_uploads_per_torrent", isOn: $model.maxUploadsPerTorrentEnabled, value: $model.maxUploadsPerTorrent, minimum: 1)
                Toggle(SettingsCatalog.title("reannounce_when_address_changed"), isOn: $model.draft.advanced.reannounceWhenAddressChanged)
                    .setting("reannounce_when_address_changed")
                HStack(spacing: Design.Spacing.small) {
                    Toggle(SettingsCatalog.title("ssl_enabled"), isOn: $model.draft.connection.sslEnabled)
                    SpinControl(title: SettingsCatalog.key("ssl_enabled"), value: $model.draft.connection.sslListenPort, range: 1...65_535)
                        .disabled(!connection.sslEnabled)
                }
                .setting("ssl_enabled")
            }
        }
    }

    /// A checkbox enabling a connection limit, with its value ("-1 = unlimited" when off).
    private func limitRow(_ id: String, isOn: Binding<Bool>, value: Binding<Int64>, minimum: Int64) -> some View {
        HStack(spacing: Design.Spacing.small) {
            Toggle(SettingsCatalog.title(id), isOn: isOn)
            SpinControl(title: SettingsCatalog.key(id), value: value, range: minimum...Int64(Int32.max))
                .disabled(!isOn.wrappedValue)
        }
        .setting(id)
    }
}
