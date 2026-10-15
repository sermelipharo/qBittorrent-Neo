import SwiftUI

/// Advanced › Network Tuning, Peers & Uploading, Trackers & Announcing and DHT (expert).
struct AdvancedNetworkGroups: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        SettingsGroup(.networkTuning) {
            spin("connection_speed", $model.draft.advanced.connectionSpeed, 0...Int64(Int32.max))
            spin("socket_send_buffer_size", $model.socketSendBufferKiB, 0...Int64(Int32.max), unit: UnitFormatter.kib,
                 special: .text(String(localized: "0 (system default)")), wide: true)
            spin("socket_receive_buffer_size", $model.socketReceiveBufferKiB, 0...Int64(Int32.max), unit: UnitFormatter.kib,
                 special: .text(String(localized: "0 (system default)")), wide: true)
            spin("socket_backlog_size", $model.draft.advanced.socketBacklogSize, 1...Int64(Int32.max))
            spin("outgoing_ports_min", $model.draft.advanced.outgoingPortsMin, 0...65_535, special: .text(String(localized: "0 (disabled)")))
            spin("outgoing_ports_max", $model.draft.advanced.outgoingPortsMax, 0...65_535, special: .text(String(localized: "0 (disabled)")))
            spin("upnp_lease_duration", $model.draft.advanced.upnpLeaseDuration, 0...Int64(Int32.max), unit: "s",
                 special: .text(String(localized: "0 (permanent lease)")), wide: true)
            spin("peer_tos", $model.draft.advanced.peerTos, 0...255)
            Picker(SettingsCatalog.title("utp_tcp_mixed_mode"), selection: $model.draft.advanced.utpTcpMixedMode) {
                ForEach(AdvancedChoices.mixedModes, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .setting("utp_tcp_mixed_mode")
            spin("hostname_cache_ttl", $model.draft.advanced.hostnameCacheTtl, 0...Int64(Int32.max), unit: "s")
            Toggle(SettingsCatalog.title("enable_multi_connections_from_same_ip"), isOn: $model.draft.advanced.enableMultiConnectionsFromSameIp)
                .setting("enable_multi_connections_from_same_ip")
            Toggle(SettingsCatalog.title("enable_upload_suggestions"), isOn: $model.draft.advanced.enableUploadSuggestions)
                .setting("enable_upload_suggestions")
            spin("send_buffer_watermark", $model.draft.advanced.sendBufferWatermark, 1...Int64(Int32.max), unit: UnitFormatter.kib)
            spin("send_buffer_low_watermark", $model.draft.advanced.sendBufferLowWatermark, 1...Int64(Int32.max), unit: UnitFormatter.kib)
            spin("send_buffer_watermark_factor", $model.draft.advanced.sendBufferWatermarkFactor, 1...Int64(Int32.max), unit: "%")
        }

        SettingsGroup(.peersUploading) {
            Picker(SettingsCatalog.title("upload_slots_behavior"), selection: $model.draft.advanced.uploadSlotsBehavior) {
                ForEach(AdvancedChoices.slotBehaviors, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .setting("upload_slots_behavior")
            Picker(SettingsCatalog.title("upload_choking_algorithm"), selection: $model.draft.advanced.uploadChokingAlgorithm) {
                ForEach(AdvancedChoices.chokingAlgorithms, id: \.self) { Text(AdvancedChoices.title($0)).tag($0) }
            }
            .setting("upload_choking_algorithm")
            spin("peer_turnover", $model.draft.advanced.peerTurnover, 0...100, unit: "%")
            spin("peer_turnover_cutoff", $model.draft.advanced.peerTurnoverCutoff, 0...100, unit: "%")
            spin("peer_turnover_interval", $model.draft.advanced.peerTurnoverInterval, 30...3_600, unit: "s")
            spin("request_queue_size", $model.draft.advanced.requestQueueSize, 1...Int64(Int32.max))
        }

        SettingsGroup(.trackersAnnouncing) {
            Toggle(SettingsCatalog.title("announce_to_all_trackers"), isOn: $model.draft.advanced.announceToAllTrackers)
                .setting("announce_to_all_trackers")
            Toggle(SettingsCatalog.title("announce_to_all_tiers"), isOn: $model.draft.advanced.announceToAllTiers)
                .setting("announce_to_all_tiers")
            CommitTextField(title: SettingsCatalog.key("announce_ip"), text: $model.draft.advanced.announceIp, trims: true)
                .setting("announce_ip")
            spin("announce_port", $model.draft.advanced.announcePort, 0...65_535)
            spin("max_concurrent_http_announces", $model.draft.advanced.maxConcurrentHttpAnnounces, 0...Int64(Int32.max))
            spin("stop_tracker_timeout", $model.draft.advanced.stopTrackerTimeout, 0...Int64(Int32.max), unit: "s",
                 special: .text(String(localized: "0 (disabled)")))
        }

        SettingsGroup(.dht) {
            CommitTextField(title: SettingsCatalog.key("dht_bootstrap_nodes"), text: $model.draft.advanced.dhtBootstrapNodes,
                            prompt: String(localized: "Resets to default if empty"), trims: true)
                .setting("dht_bootstrap_nodes")
        }
    }

    private func spin(
        _ id: String, _ value: Binding<Int64>, _ range: ClosedRange<Int64>, unit: String? = nil, special: SpinSpecial? = nil, wide: Bool = false
    ) -> some View {
        SpinField(title: SettingsCatalog.key(id), value: value, range: range, unit: unit, special: special,
                  width: wide ? FeatureDesign.Width.wideSpinField : FeatureDesign.Width.spinField)
            .setting(id)
    }
}
