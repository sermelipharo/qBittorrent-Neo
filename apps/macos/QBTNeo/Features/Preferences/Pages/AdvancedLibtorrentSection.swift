import SwiftUI

/// Advanced › "libtorrent Section". The engine maps each setting to its
/// closest equivalent (see docs/ENGINE.md).
struct AdvancedLibtorrentSection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Section {
            SpinField(title: "Bdecode depth limit", value: $model.draft.advanced.bdecodeDepthLimit, range: 0...Int64(Int32.max))
            SpinField(title: "Bdecode token limit", value: $model.draft.advanced.bdecodeTokenLimit, range: 0...Int64(Int32.max),
                      width: FeatureDesign.Width.wideSpinField)
            SpinField(title: "Asynchronous I/O threads", value: $model.draft.advanced.asyncIoThreads, range: 1...1_024)
            SpinField(title: "Hashing threads", value: $model.draft.advanced.hashingThreads, range: 1...1_024)
            SpinField(title: "File pool size", value: $model.draft.advanced.filePoolSize, range: 1...Int64(Int32.max))
            SpinField(title: "Outstanding memory when checking torrents", value: $model.draft.advanced.checkingMemoryUse,
                      range: 1...1_024, unit: UnitFormatter.mib)
            SpinField(title: "Disk queue size", value: $model.diskQueueSizeKiB, range: 1...Int64(Int32.max), unit: UnitFormatter.kib,
                      width: FeatureDesign.Width.wideSpinField)
            Picker("Disk IO type (requires restart)", selection: $model.draft.advanced.diskIoType) {
                ForEach(AdvancedChoices.diskIOTypes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            Picker("Disk IO read mode", selection: $model.draft.advanced.diskIoReadMode) {
                ForEach(AdvancedChoices.readModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            Picker("Disk IO write mode", selection: $model.draft.advanced.diskIoWriteMode) {
                ForEach(AdvancedChoices.writeModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            Toggle("Use piece extent affinity", isOn: $model.draft.advanced.enablePieceExtentAffinity)
            Toggle("Send upload piece suggestions", isOn: $model.draft.advanced.enableUploadSuggestions)
            SpinField(title: "Send buffer watermark", value: $model.draft.advanced.sendBufferWatermark, range: 1...Int64(Int32.max), unit: UnitFormatter.kib)
            SpinField(title: "Send buffer low watermark", value: $model.draft.advanced.sendBufferLowWatermark,
                      range: 1...Int64(Int32.max), unit: UnitFormatter.kib)
            SpinField(title: "Send buffer watermark factor", value: $model.draft.advanced.sendBufferWatermarkFactor,
                      range: 1...Int64(Int32.max), unit: "%")
            SpinField(title: "Outgoing connections per second", value: $model.draft.advanced.connectionSpeed, range: 0...Int64(Int32.max))
            SpinField(title: "Socket send buffer size [0: system default]", value: $model.socketSendBufferKiB,
                      range: 0...Int64(Int32.max), unit: UnitFormatter.kib, special: .text(String(localized: "0 (system default)")),
                      width: FeatureDesign.Width.wideSpinField)
            SpinField(title: "Socket receive buffer size [0: system default]", value: $model.socketReceiveBufferKiB,
                      range: 0...Int64(Int32.max), unit: UnitFormatter.kib, special: .text(String(localized: "0 (system default)")),
                      width: FeatureDesign.Width.wideSpinField)
            SpinField(title: "Socket backlog size", value: $model.draft.advanced.socketBacklogSize, range: 1...Int64(Int32.max))
            SpinField(title: "Outgoing ports (Min) [0: disabled]", value: $model.draft.advanced.outgoingPortsMin,
                      range: 0...65_535, special: .text(String(localized: "0 (disabled)")))
            SpinField(title: "Outgoing ports (Max) [0: disabled]", value: $model.draft.advanced.outgoingPortsMax,
                      range: 0...65_535, special: .text(String(localized: "0 (disabled)")))
            SpinField(title: "UPnP lease duration [0: permanent lease]", value: $model.draft.advanced.upnpLeaseDuration,
                      range: 0...Int64(Int32.max), unit: "s", special: .text(String(localized: "0 (permanent lease)")),
                      width: FeatureDesign.Width.wideSpinField)
            SpinField(title: "Differentiated Services Code Point (DSCP) for connections to peers", value: $model.draft.advanced.peerTos,
                      range: 0...255)
            Picker("μTP-TCP mixed mode algorithm", selection: $model.draft.advanced.utpTcpMixedMode) {
                ForEach(AdvancedChoices.mixedModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            SpinField(title: "Internal hostname resolver cache expiry interval", value: $model.draft.advanced.hostnameCacheTtl,
                      range: 0...Int64(Int32.max), unit: "s")
            Toggle("Support internationalized domain name (IDN)", isOn: $model.draft.advanced.idnSupportEnabled)
            Toggle("Allow multiple connections from the same IP address", isOn: $model.draft.advanced.enableMultiConnectionsFromSameIp)
            Toggle("Validate HTTPS tracker certificates", isOn: $model.draft.advanced.validateHttpsTrackerCertificate)
            Toggle("Server-side request forgery (SSRF) mitigation", isOn: $model.draft.advanced.ssrfMitigation)
            Toggle("Disallow connection to peers on privileged ports", isOn: $model.draft.advanced.blockPeersOnPrivilegedPorts)
            Picker("Upload slots behavior", selection: $model.draft.advanced.uploadSlotsBehavior) {
                ForEach(AdvancedChoices.slotBehaviors, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            Picker("Upload choking algorithm", selection: $model.draft.advanced.uploadChokingAlgorithm) {
                ForEach(AdvancedChoices.chokingAlgorithms, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            Toggle("Always announce to all trackers in a tier", isOn: $model.draft.advanced.announceToAllTrackers)
            Toggle("Always announce to all tiers", isOn: $model.draft.advanced.announceToAllTiers)
            CommitTextField(title: "IP address reported to trackers (requires restart)", text: $model.draft.advanced.announceIp, trims: true)
            SpinField(title: "Port reported to trackers (requires restart) [0: listening port]", value: $model.draft.advanced.announcePort,
                      range: 0...65_535)
            SpinField(title: "Max concurrent HTTP announces", value: $model.draft.advanced.maxConcurrentHttpAnnounces, range: 0...Int64(Int32.max))
            SpinField(title: "Stop tracker timeout [0: disabled]", value: $model.draft.advanced.stopTrackerTimeout,
                      range: 0...Int64(Int32.max), unit: "s", special: .text(String(localized: "0 (disabled)")))
            SpinField(title: "Peer turnover disconnect percentage", value: $model.draft.advanced.peerTurnover, range: 0...100, unit: "%")
            SpinField(title: "Peer turnover threshold percentage", value: $model.draft.advanced.peerTurnoverCutoff, range: 0...100, unit: "%")
            SpinField(title: "Peer turnover disconnect interval", value: $model.draft.advanced.peerTurnoverInterval, range: 30...3_600, unit: "s")
            SpinField(title: "Maximum outstanding requests to a single peer", value: $model.draft.advanced.requestQueueSize,
                      range: 1...Int64(Int32.max))
            CommitTextField(title: "DHT bootstrap nodes", text: $model.draft.advanced.dhtBootstrapNodes,
                            prompt: String(localized: "Resets to default if empty"), trims: true)
            SpinField(title: "I2P inbound quantity", value: $model.draft.connection.i2pInboundQuantity, range: 1...16)
            SpinField(title: "I2P outbound quantity", value: $model.draft.connection.i2pOutboundQuantity, range: 1...16)
            SpinField(title: "I2P inbound length", value: $model.draft.connection.i2pInboundLength, range: 0...7)
            SpinField(title: "I2P outbound length", value: $model.draft.connection.i2pOutboundLength, range: 0...7)
        } header: {
            AdvancedSectionHeader(title: "libtorrent Section", documentation: PreferenceLinks.libtorrentDocs)
        }
    }
}
