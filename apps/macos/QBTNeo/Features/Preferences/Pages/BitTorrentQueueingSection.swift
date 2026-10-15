import SwiftUI

/// BitTorrent › Torrent Queueing (checkable group) with the slow-torrent rules.
struct BitTorrentQueueingSection: View {
    @Bindable var model: PreferencesModel

    private static let slowHelp: LocalizedStringKey = """
        A torrent will be considered slow if its download and upload rates stay below these values for \
        "Torrent inactivity timer" seconds
        """

    var body: some View {
        CheckableSection(title: "Torrent Queueing", isOn: $model.draft.bittorrent.queueingEnabled) {
            SpinField(title: "Maximum active downloads:", value: $model.draft.bittorrent.maxActiveDownloads,
                      range: -1...Int64(Int32.max), special: .infinity(at: -1))
            SpinField(title: "Maximum active uploads:", value: $model.draft.bittorrent.maxActiveUploads,
                      range: -1...Int64(Int32.max), special: .infinity(at: -1))
            SpinField(title: "Maximum active torrents:", value: $model.draft.bittorrent.maxActiveTorrents,
                      range: -1...Int64(Int32.max), special: .infinity(at: -1))
            Toggle("Do not count slow torrents in these limits", isOn: $model.draft.bittorrent.dontCountSlowTorrents)
            Group {
                SpinField(title: "Download rate threshold:", value: $model.draft.bittorrent.slowTorrentDlRateThreshold,
                          range: 0...2_000_000, unit: UnitFormatter.kibPerSecond)
                SpinField(title: "Upload rate threshold:", value: $model.draft.bittorrent.slowTorrentUlRateThreshold,
                          range: 0...2_000_000, unit: UnitFormatter.kibPerSecond)
                SpinField(title: "Torrent inactivity timer:", value: $model.draft.bittorrent.slowTorrentInactiveTimer,
                          range: 1...999_999, unit: String(localized: "sec"))
            }
            .help(Self.slowHelp)
            .disabled(!model.draft.bittorrent.dontCountSlowTorrents)
            .padding(.leading, Design.Spacing.xLarge)
        }
    }
}
