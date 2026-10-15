import SwiftUI

/// Settings › Connection (preferences.md §3).
struct ConnectionPage: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Form {
            Section {
                Picker("Peer connection protocol:", selection: $model.draft.connection.bittorrentProtocol) {
                    ForEach(PreferenceChoices.protocols, id: \.self) { value in
                        Text(PreferenceChoices.title(value)).tag(value)
                    }
                }
            }

            Section("Listening Port") {
                LabeledContent("Port used for incoming connections:") {
                    HStack(spacing: Design.Spacing.small) {
                        SpinControl(
                            title: "Port used for incoming connections:", value: $model.draft.connection.listenPort,
                            range: 0...65_535, special: .text(String(localized: "Any"))
                        )
                        .help("Set to 0 to let your system pick an unused port")
                        Button("Random", action: randomPort)
                    }
                }
                Toggle("Use UPnP / NAT-PMP port forwarding from my router", isOn: $model.draft.connection.upnp)
            }

            Section("Connections Limits") {
                LimitRow(title: "Global maximum number of connections:", isOn: $model.maxConnectionsEnabled,
                         value: $model.maxConnections, range: 2...Int64(Int32.max))
                LimitRow(title: "Maximum number of connections per torrent:", isOn: $model.maxConnectionsPerTorrentEnabled,
                         value: $model.maxConnectionsPerTorrent, range: 2...Int64(Int32.max))
                LimitRow(title: "Global maximum number of upload slots:", isOn: $model.maxUploadsEnabled,
                         value: $model.maxUploads, range: 1...Int64(Int32.max))
                LimitRow(title: "Maximum number of upload slots per torrent:", isOn: $model.maxUploadsPerTorrentEnabled,
                         value: $model.maxUploadsPerTorrent, range: 1...Int64(Int32.max))
            }

            CheckableSection(title: "I2P (experimental)", isOn: $model.draft.connection.i2pEnabled) {
                CommitTextField(title: "Host:", text: $model.draft.connection.i2pAddress, trims: true)
                SpinField(title: "Port:", value: $model.draft.connection.i2pPort, range: 1...65_535)
                Toggle("Mixed mode", isOn: $model.draft.connection.i2pMixedMode)
                    .help("""
                        If "mixed mode" is enabled I2P torrents are allowed to also get peers from other sources than \
                        the tracker, and connect to regular IPs, not providing any anonymization. This may be useful \
                        if the user is not interested in the anonymization of I2P, but still wants to be able to \
                        connect to I2P peers.
                        """)
            }

            ProxySection(model: model)
            IPFilterSection(model: model)
        }
    }

    private func randomPort() {
        model.draft.connection.listenPort = Int64.random(in: 1_024...65_535)
    }
}
