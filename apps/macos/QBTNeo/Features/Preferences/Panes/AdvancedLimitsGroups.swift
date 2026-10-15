import SwiftUI

/// Advanced › Safety Limits and Embedded Tracker (expert).
struct AdvancedLimitsGroups: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        SettingsGroup(.safetyLimits) {
            spin("torrent_file_size_limit", $model.torrentFileSizeLimitMiB, 1...2_047, unit: UnitFormatter.mib)
            spin("bdecode_depth_limit", $model.draft.advanced.bdecodeDepthLimit, 0...Int64(Int32.max))
            spin("bdecode_token_limit", $model.draft.advanced.bdecodeTokenLimit, 0...Int64(Int32.max), wide: true)
        }

        SettingsGroup(.embeddedTracker) {
            Toggle(SettingsCatalog.title("enable_embedded_tracker"), isOn: $model.draft.advanced.enableEmbeddedTracker)
                .setting("enable_embedded_tracker")
            spin("embedded_tracker_port", $model.draft.advanced.embeddedTrackerPort, 1...65_535)
            Toggle(SettingsCatalog.title("embedded_tracker_port_forwarding"), isOn: $model.draft.advanced.embeddedTrackerPortForwarding)
                .setting("embedded_tracker_port_forwarding")
        }
    }

    private func spin(_ id: String, _ value: Binding<Int64>, _ range: ClosedRange<Int64>, unit: String? = nil, wide: Bool = false) -> some View {
        SpinField(title: SettingsCatalog.key(id), value: value, range: range, unit: unit,
                  width: wide ? FeatureDesign.Width.wideSpinField : FeatureDesign.Width.spinField)
            .setting(id)
    }
}
