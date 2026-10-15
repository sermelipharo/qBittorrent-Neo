import SwiftUI

/// Transfers › Seeding & Queue: seeding limits, the active-torrents queue and checking.
struct TransfersSeedingSegment: View {
    @Bindable var model: PreferencesModel

    private static let slowHelp: LocalizedStringKey = """
        A torrent will be considered slow if its download and upload rates stay below these values for \
        "Torrent inactivity timer" seconds
        """

    var body: some View {
        let bittorrent = model.draft.bittorrent
        SettingsGroup(.seedingLimits) {
            limitRow("max_ratio_enabled", isOn: $model.maxRatioEnabled) {
                DecimalSpinControl(title: SettingsCatalog.key("max_ratio_enabled"), value: $model.maxRatio, width: FeatureDesign.Width.wideSpinField)
            }
            limitRow("max_seeding_time_enabled", isOn: $model.maxSeedingTimeEnabled) {
                SpinControl(title: SettingsCatalog.key("max_seeding_time_enabled"), value: $model.maxSeedingTime, range: 0...9_999_999,
                            unit: String(localized: "min"), width: FeatureDesign.Width.wideSpinField)
            }
            limitRow("max_inactive_seeding_time_enabled", isOn: $model.maxInactiveSeedingTimeEnabled) {
                SpinControl(title: SettingsCatalog.key("max_inactive_seeding_time_enabled"), value: $model.maxInactiveSeedingTime,
                            range: 0...9_999_999, unit: String(localized: "min"), width: FeatureDesign.Width.wideSpinField)
            }
            Picker(SettingsCatalog.title("max_ratio_act"), selection: $model.draft.bittorrent.maxRatioAct) {
                ForEach(PreferenceChoices.shareLimitActions, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
            }
            .fixedSize()
            .disabled(!model.anySeedingLimitEnabled)
            .setting("max_ratio_act")
        } footer: {
            SettingFootnote(text: String(localized: "Ratio = uploaded ÷ downloaded. 1.0 means you shared as much as you took."))
        }

        SettingsGroup(.queue) {
            Toggle(SettingsCatalog.title("queueing_enabled"), isOn: $model.draft.bittorrent.queueingEnabled)
                .setting("queueing_enabled")
        } content: {
            Group {
                activeLimit("max_active_downloads", value: $model.draft.bittorrent.maxActiveDownloads)
                activeLimit("max_active_uploads", value: $model.draft.bittorrent.maxActiveUploads)
                activeLimit("max_active_torrents", value: $model.draft.bittorrent.maxActiveTorrents)
                Toggle(SettingsCatalog.title("dont_count_slow_torrents"), isOn: $model.draft.bittorrent.dontCountSlowTorrents)
                    .setting("dont_count_slow_torrents")
                Group {
                    SpinField(title: SettingsCatalog.key("slow_torrent_dl_rate_threshold"), value: $model.draft.bittorrent.slowTorrentDlRateThreshold,
                              range: 0...2_000_000, unit: UnitFormatter.kibPerSecond)
                        .setting("slow_torrent_dl_rate_threshold")
                    SpinField(title: SettingsCatalog.key("slow_torrent_ul_rate_threshold"), value: $model.draft.bittorrent.slowTorrentUlRateThreshold,
                              range: 0...2_000_000, unit: UnitFormatter.kibPerSecond)
                        .setting("slow_torrent_ul_rate_threshold")
                    SpinField(title: SettingsCatalog.key("slow_torrent_inactive_timer"), value: $model.draft.bittorrent.slowTorrentInactiveTimer,
                              range: 1...999_999, unit: String(localized: "sec"))
                        .setting("slow_torrent_inactive_timer")
                }
                .help(Self.slowHelp)
                .disabled(!bittorrent.dontCountSlowTorrents)
            }
            .disabled(!bittorrent.queueingEnabled)
        }

        SettingsGroup(.checking) {
            SpinField(title: SettingsCatalog.key("max_active_checking_torrents"), value: $model.draft.bittorrent.maxActiveCheckingTorrents,
                      range: -1...Int64(Int32.max), special: .infinity(at: -1))
                .setting("max_active_checking_torrents")
        }
    }

    private func activeLimit(_ id: String, value: Binding<Int64>) -> some View {
        SpinField(title: SettingsCatalog.key(id), value: value, range: -1...Int64(Int32.max), special: .infinity(at: -1))
            .setting(id)
    }

    /// "When … reaches" in the label column; its checkbox and value line up in the controls column.
    private func limitRow(_ id: String, isOn: Binding<Bool>, @ViewBuilder control: () -> some View) -> some View {
        LabeledContent(SettingsCatalog.key(id)) {
            HStack(spacing: Design.Spacing.small) {
                Toggle(SettingsCatalog.title(id), isOn: isOn)
                    .labelsHidden()
                control()
                    .disabled(!isOn.wrappedValue)
            }
        }
        .setting(id)
    }
}
