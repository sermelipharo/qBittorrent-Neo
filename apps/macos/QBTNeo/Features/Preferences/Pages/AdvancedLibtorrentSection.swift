import SwiftUI

/// Advanced › "libtorrent Section". The engine maps each setting to its
/// closest equivalent (see docs/ENGINE.md).
struct AdvancedLibtorrentSection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Section {
            SpinField(title: "Bdecode depth limit", value: $model.draft.advanced.bdecodeDepthLimit, range: 0...Int64(Int32.max))
                .settingAnchor("advanced.1")
            SpinField(title: "Bdecode token limit", value: $model.draft.advanced.bdecodeTokenLimit, range: 0...Int64(Int32.max),
                      width: FeatureDesign.Width.wideSpinField).settingAnchor("advanced.2")
            SpinField(title: "Asynchronous I/O threads", value: $model.draft.advanced.asyncIoThreads, range: 1...1_024).settingAnchor("advanced.3")
            SpinField(title: "Hashing threads", value: $model.draft.advanced.hashingThreads, range: 1...1_024).settingAnchor("advanced.4")
            SpinField(title: "File pool size", value: $model.draft.advanced.filePoolSize, range: 1...Int64(Int32.max)).settingAnchor("advanced.5")
            SpinField(title: "Outstanding memory when checking torrents", value: $model.draft.advanced.checkingMemoryUse,
                      range: 1...1_024, unit: UnitFormatter.mib).settingAnchor("advanced.6")
            SpinField(title: "Disk queue size", value: $model.diskQueueSizeKiB, range: 1...Int64(Int32.max), unit: UnitFormatter.kib,
                      width: FeatureDesign.Width.wideSpinField).settingAnchor("advanced.7")
            Picker("Disk IO type (requires restart)", selection: $model.draft.advanced.diskIoType) {
                ForEach(AdvancedChoices.diskIOTypes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }.settingAnchor("advanced.8")
            Picker("Disk IO read mode", selection: $model.draft.advanced.diskIoReadMode) {
                ForEach(AdvancedChoices.readModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }.settingAnchor("advanced.9")
            Picker("Disk IO write mode", selection: $model.draft.advanced.diskIoWriteMode) {
                ForEach(AdvancedChoices.writeModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }.settingAnchor("advanced.10")
            Toggle("Use piece extent affinity", isOn: $model.draft.advanced.enablePieceExtentAffinity).settingAnchor("advanced.11")
            Toggle("Send upload piece suggestions", isOn: $model.draft.advanced.enableUploadSuggestions).settingAnchor("advanced.12")
            SpinField(title: "Send buffer watermark", value: $model.draft.advanced.sendBufferWatermark, range: 1...Int64(Int32.max), unit: UnitFormatter.kib)
                .settingAnchor("advanced.13")
            SpinField(title: "Send buffer low watermark", value: $model.draft.advanced.sendBufferLowWatermark,
                      range: 1...Int64(Int32.max), unit: UnitFormatter.kib).settingAnchor("advanced.14")
            SpinField(title: "Send buffer watermark factor", value: $model.draft.advanced.sendBufferWatermarkFactor,
                      range: 1...Int64(Int32.max), unit: "%").settingAnchor("advanced.15")
            SpinField(title: "Outgoing connections per second", value: $model.draft.advanced.connectionSpeed, range: 0...Int64(Int32.max))
                .settingAnchor("advanced.16")
            SpinField(title: "Socket send buffer size [0: system default]", value: $model.socketSendBufferKiB,
                      range: 0...Int64(Int32.max), unit: UnitFormatter.kib, special: .text(String(localized: "0 (system default)")),
                      width: FeatureDesign.Width.wideSpinField).settingAnchor("advanced.17")
            SpinField(title: "Socket receive buffer size [0: system default]", value: $model.socketReceiveBufferKiB,
                      range: 0...Int64(Int32.max), unit: UnitFormatter.kib, special: .text(String(localized: "0 (system default)")),
                      width: FeatureDesign.Width.wideSpinField).settingAnchor("advanced.18")
            SpinField(title: "Socket backlog size", value: $model.draft.advanced.socketBacklogSize, range: 1...Int64(Int32.max))
                .settingAnchor("advanced.19")
            SpinField(title: "Outgoing ports (Min) [0: disabled]", value: $model.draft.advanced.outgoingPortsMin,
                      range: 0...65_535, special: .text(String(localized: "0 (disabled)"))).settingAnchor("advanced.20")
            SpinField(title: "Outgoing ports (Max) [0: disabled]", value: $model.draft.advanced.outgoingPortsMax,
                      range: 0...65_535, special: .text(String(localized: "0 (disabled)"))).settingAnchor("advanced.21")
            SpinField(title: "UPnP lease duration [0: permanent lease]", value: $model.draft.advanced.upnpLeaseDuration,
                      range: 0...Int64(Int32.max), unit: "s", special: .text(String(localized: "0 (permanent lease)")),
                      width: FeatureDesign.Width.wideSpinField).settingAnchor("advanced.22")
            SpinField(title: "Differentiated Services Code Point (DSCP) for connections to peers", value: $model.draft.advanced.peerTos,
                      range: 0...255).settingAnchor("advanced.23")
            Picker("μTP-TCP mixed mode algorithm", selection: $model.draft.advanced.utpTcpMixedMode) {
                ForEach(AdvancedChoices.mixedModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }.settingAnchor("advanced.24")
            SpinField(title: "Internal hostname resolver cache expiry interval", value: $model.draft.advanced.hostnameCacheTtl,
                      range: 0...Int64(Int32.max), unit: "s").settingAnchor("advanced.25")
            Toggle("Support internationalized domain name (IDN)", isOn: $model.draft.advanced.idnSupportEnabled).settingAnchor("advanced.26")
            Toggle("Allow multiple connections from the same IP address", isOn: $model.draft.advanced.enableMultiConnectionsFromSameIp)
                .settingAnchor("advanced.27")
            Toggle("Validate HTTPS tracker certificates", isOn: $model.draft.advanced.validateHttpsTrackerCertificate).settingAnchor("advanced.28")
            Toggle("Server-side request forgery (SSRF) mitigation", isOn: $model.draft.advanced.ssrfMitigation).settingAnchor("advanced.29")
            Toggle("Disallow connection to peers on privileged ports", isOn: $model.draft.advanced.blockPeersOnPrivilegedPorts)
                .settingAnchor("advanced.30")
            Picker("Upload slots behavior", selection: $model.draft.advanced.uploadSlotsBehavior) {
                ForEach(AdvancedChoices.slotBehaviors, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }.settingAnchor("advanced.31")
            Picker("Upload choking algorithm", selection: $model.draft.advanced.uploadChokingAlgorithm) {
                ForEach(AdvancedChoices.chokingAlgorithms, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }.settingAnchor("advanced.32")
            Toggle("Always announce to all trackers in a tier", isOn: $model.draft.advanced.announceToAllTrackers).settingAnchor("advanced.33")
            Toggle("Always announce to all tiers", isOn: $model.draft.advanced.announceToAllTiers).settingAnchor("advanced.34")
            CommitTextField(title: "IP address reported to trackers (requires restart)", text: $model.draft.advanced.announceIp, trims: true)
                .settingAnchor("advanced.35")
            SpinField(title: "Port reported to trackers (requires restart) [0: listening port]", value: $model.draft.advanced.announcePort,
                      range: 0...65_535).settingAnchor("advanced.36")
            SpinField(title: "Max concurrent HTTP announces", value: $model.draft.advanced.maxConcurrentHttpAnnounces, range: 0...Int64(Int32.max))
                .settingAnchor("advanced.37")
            SpinField(title: "Stop tracker timeout [0: disabled]", value: $model.draft.advanced.stopTrackerTimeout,
                      range: 0...Int64(Int32.max), unit: "s", special: .text(String(localized: "0 (disabled)"))).settingAnchor("advanced.38")
            SpinField(title: "Peer turnover disconnect percentage", value: $model.draft.advanced.peerTurnover, range: 0...100, unit: "%")
                .settingAnchor("advanced.39")
            SpinField(title: "Peer turnover threshold percentage", value: $model.draft.advanced.peerTurnoverCutoff, range: 0...100, unit: "%")
                .settingAnchor("advanced.40")
            SpinField(title: "Peer turnover disconnect interval", value: $model.draft.advanced.peerTurnoverInterval, range: 30...3_600, unit: "s")
                .settingAnchor("advanced.41")
            SpinField(title: "Maximum outstanding requests to a single peer", value: $model.draft.advanced.requestQueueSize,
                      range: 1...Int64(Int32.max)).settingAnchor("advanced.42")
            CommitTextField(title: "DHT bootstrap nodes", text: $model.draft.advanced.dhtBootstrapNodes,
                            prompt: String(localized: "Resets to default if empty"), trims: true).settingAnchor("advanced.43")
            SpinField(title: "I2P inbound quantity", value: $model.draft.connection.i2pInboundQuantity, range: 1...16).settingAnchor("advanced.44")
            SpinField(title: "I2P outbound quantity", value: $model.draft.connection.i2pOutboundQuantity, range: 1...16).settingAnchor("advanced.45")
            SpinField(title: "I2P inbound length", value: $model.draft.connection.i2pInboundLength, range: 0...7).settingAnchor("advanced.46")
            SpinField(title: "I2P outbound length", value: $model.draft.connection.i2pOutboundLength, range: 0...7).settingAnchor("advanced.47")
        } header: {
            AdvancedSectionHeader(title: "libtorrent Section", documentation: PreferenceLinks.libtorrentDocs).settingAnchor("advanced.48")
        }
    }
}
