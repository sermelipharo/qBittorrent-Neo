import SwiftUI

/// Settings › Advanced (preferences.md §9): "qBittorrent Section" and
/// "libtorrent Section" in the spec's row order, macOS rows only.
struct AdvancedPage: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui
    @State private var network = NetworkInterfacesModel()

    var body: some View {
        @Bindable var gui = gui
        Form {
            Section {
                Picker("Resume data storage type (requires restart)", selection: $model.draft.advanced.resumeDataStorageType) {
                    ForEach(AdvancedChoices.resumeStorage, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
                }
                Picker("Torrent content removing mode", selection: $model.draft.advanced.torrentContentRemoveOption) {
                    ForEach(AdvancedChoices.removeOptions, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
                }
                Picker("Network interface", selection: $model.draft.advanced.currentNetworkInterface) {
                    ForEach(network.interfaceChoices(selected: model.draft.advanced.currentNetworkInterface,
                                                     savedName: model.draft.advanced.currentInterfaceName), id: \.value) { choice in
                        Text(choice.title).tag(choice.value)
                    }
                }
                Picker("Optional IP address to bind to", selection: $model.draft.advanced.currentInterfaceAddress) {
                    ForEach(network.addressChoices(selected: model.draft.advanced.currentInterfaceAddress), id: \.value) { choice in
                        Text(choice.title).tag(choice.value)
                    }
                }
                SpinField(title: "Save resume data interval [0: disabled]", value: $model.draft.advanced.saveResumeDataInterval,
                          range: 0...Int64(Int32.max), unit: String(localized: "min"), special: .text(String(localized: "0 (disabled)")))
                SpinField(title: "Save statistics interval [0: disabled]", value: $model.draft.advanced.saveStatisticsInterval,
                          range: 0...Int64(Int32.max), unit: String(localized: "min"), special: .text(String(localized: "0 (disabled)")))
                SpinField(title: ".torrent file size limit", value: $model.torrentFileSizeLimitMiB, range: 1...2_047, unit: UnitFormatter.mib)
                Toggle("Confirm torrent recheck", isOn: $model.draft.advanced.confirmTorrentRecheck)
                Toggle("Recheck torrents on completion", isOn: $model.draft.advanced.recheckCompletedTorrents)
                CommitTextField(title: "Customize application instance name", text: $model.draft.advanced.appInstanceName, trims: true)
                    .help("It appends the text to the window title to help distinguish qBittorrent Neo instances")
                SpinField(title: "Refresh interval", value: $model.draft.advanced.refreshInterval, range: 30...99_999, unit: "ms")
                    .help("It controls the internal state update interval which in turn will affect UI updates")
                Toggle("Resolve peer host names", isOn: $model.draft.advanced.resolvePeerHostNames)
                Toggle("Resolve peer countries", isOn: $model.draft.advanced.resolvePeerCountries)
                Toggle("Display notifications", isOn: $gui.notificationsEnabled)
                Toggle("Display notifications for added torrents", isOn: $gui.notifyTorrentAdded)
                Toggle("Confirm removal of all tags", isOn: $gui.confirmRemoveAllTags)
                Toggle("Confirm removal of tracker from all torrents", isOn: $gui.confirmRemoveTrackerFromAllTorrents)
                Toggle("Reannounce to all trackers when IP or port changed", isOn: $model.draft.advanced.reannounceWhenAddressChanged)
                Toggle("Download tracker's favicon", isOn: $gui.downloadTrackerFavicon)
                SpinField(title: "Save path history length", value: $gui.savePathHistoryLengthValue, range: 0...99)
                Toggle("Enable speed graphs", isOn: $gui.speedGraphsEnabled)
                Toggle("Enable embedded tracker", isOn: $model.draft.advanced.enableEmbeddedTracker)
                SpinField(title: "Embedded tracker port", value: $model.draft.advanced.embeddedTrackerPort, range: 1...65_535)
                Toggle("Enable port forwarding for embedded tracker", isOn: $model.draft.advanced.embeddedTrackerPortForwarding)
                Toggle("Enable quarantine for downloaded files", isOn: $model.draft.advanced.markOfTheWeb)
                Toggle("Ignore SSL errors", isOn: $model.draft.advanced.ignoreSslErrors)
                    .help("Affects certificate validation and non-torrent protocol activities (e.g. RSS feeds, program updates, torrent files, geoip db, etc)")
                CommitTextField(title: "Python executable path (may require restart)", text: $model.draft.advanced.pythonExecutablePath,
                                prompt: String(localized: "(Auto detect if empty)"), trims: true)
                Toggle("Start BitTorrent session in paused state", isOn: $model.draft.advanced.startPaused)
                SpinField(title: "BitTorrent session shutdown timeout [-1: unlimited]", value: $model.draft.advanced.shutdownTimeout,
                          range: -1...Int64(Int32.max), unit: String(localized: "sec"), special: .text(String(localized: "-1 (unlimited)"), at: -1))
                    .help("""
                        Sets the timeout for the session to be shut down gracefully, at which point it will be forcibly \
                        terminated. Note that this does not apply to the saving resume data time.
                        """)
            } header: {
                AdvancedSectionHeader(title: "qBittorrent Section", documentation: PreferenceLinks.advancedDocs)
            }

            AdvancedLibtorrentSection(model: model)
        }
        .task(id: model.draft.advanced.currentNetworkInterface) {
            await network.load(client: model.appInfo, interface: model.draft.advanced.currentNetworkInterface)
        }
    }
}
