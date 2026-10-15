import SwiftUI

/// Settings › BitTorrent (preferences.md §5).
struct BitTorrentPage: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Form {
            Section("Privacy") {
                Toggle("Enable DHT (decentralized network) to find more peers", isOn: $model.draft.bittorrent.dht)
                    .help("Find peers on the DHT network")
                Toggle("Enable Peer Exchange (PeX) to find more peers", isOn: $model.draft.bittorrent.pex)
                    .help("Exchange peers with compatible Bittorrent clients (µTorrent, Vuze, ...)")
                Toggle("Enable Local Peer Discovery to find more peers", isOn: $model.draft.bittorrent.lsd)
                    .help("Look for peers on your local network")
                Picker("Encryption mode:", selection: $model.draft.bittorrent.encryption) {
                    ForEach(PreferenceChoices.encryptionModes, id: \.self) { mode in
                        Text(PreferenceChoices.title(mode)).tag(mode)
                    }
                }
                .help("""
                    Allow encryption: Connect to peers regardless of setting
                    Require encryption: Only connect to peers with protocol encryption
                    Disable encryption: Only connect to peers without protocol encryption
                    """)
                LabeledContent {
                    Link("More information", destination: PreferenceLinks.anonymousMode)
                } label: {
                    Toggle("Enable anonymous mode", isOn: $model.draft.bittorrent.anonymousMode)
                        .help("Enable when using a proxy or a VPN connection")
                }
            }

            Section {
                SpinField(
                    title: "Maximum active checking torrents:", value: $model.draft.bittorrent.maxActiveCheckingTorrents,
                    range: -1...Int64(Int32.max), special: .infinity(at: -1)
                )
            }

            BitTorrentQueueingSection(model: model)
            BitTorrentSeedingLimitsSection(model: model)

            CheckableSection(title: "Automatically append these trackers to new downloads:", isOn: $model.draft.bittorrent.addTrackersEnabled) {
                CommitTextEditor(
                    title: "Automatically append these trackers to new downloads:", text: $model.draft.bittorrent.addTrackers,
                    minHeight: 96, prompt: String(localized: "One URL per line; an empty line starts a new tier.")
                )
            }

            CheckableSection(
                title: "Automatically append trackers from URL to new downloads:", isOn: $model.draft.bittorrent.addTrackersFromUrlEnabled
            ) {
                CommitTextField(title: "URL:", text: $model.draft.bittorrent.addTrackersUrl, prompt: "https://example.org/trackers.txt", trims: true)
                LabeledContent("Fetched trackers") {
                    ScrollView {
                        Text(model.draft.bittorrent.addTrackersUrlList.isEmpty ? String(localized: "None") : model.draft.bittorrent.addTrackersUrlList)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 96)
                }
            }
        }
    }
}
