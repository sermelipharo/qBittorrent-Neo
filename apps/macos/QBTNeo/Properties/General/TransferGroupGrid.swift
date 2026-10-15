import SwiftUI

/// "Transfer" group: a 3 × (label, value) grid (features.md §2.3.2).
struct TransferGroupGrid: View {
    let values: TorrentProperties
    let isFinished: Bool

    var body: some View {
        let v = values
        let size = UnitFormatter.size
        let speed = UnitFormatter.speed
        let maxConnections = v.connectionsLimit < 0 ? UnitFormatter.infinity : v.connectionsLimit.formatted()
        let lastSeen = v.lastSeen > 0 ? ValueFormatter.date(v.lastSeen) : String(localized: "Never")
        Grid(alignment: .leading, horizontalSpacing: Design.Spacing.regular, verticalSpacing: Design.Spacing.tight) {
            GridRow {
                PropertyValueRow(label: "Time Active:", value: timeActive)
                PropertyValueRow(label: "ETA:", value: DurationFormatter.eta(v.eta))
                PropertyValueRow(label: "Connections:", value: String(localized: "\(v.connections) (\(maxConnections) max)"))
            }
            GridRow {
                PropertyValueRow(label: "Downloaded:", value: String(localized: "\(size(v.totalDownloaded)) (\(size(v.totalDownloadedSession)) this session)"))
                PropertyValueRow(label: "Uploaded:", value: String(localized: "\(size(v.totalUploaded)) (\(size(v.totalUploadedSession)) this session)"))
                PropertyValueRow(label: "Seeds:", value: String(localized: "\(v.seeds) (\(max(v.seedsTotal, v.seeds)) total)"))
            }
            GridRow {
                PropertyValueRow(label: "Download Speed:", value: String(localized: "\(speed(v.dlSpeed)) (\(speed(v.dlSpeedAvg)) avg.)"))
                PropertyValueRow(label: "Upload Speed:", value: String(localized: "\(speed(v.upSpeed)) (\(speed(v.upSpeedAvg)) avg.)"))
                PropertyValueRow(label: "Peers:", value: String(localized: "\(v.peers) (\(max(v.peersTotal, v.peers)) total)"))
            }
            GridRow {
                PropertyValueRow(label: "Download Limit:", value: UnitFormatter.limit(v.dlLimit))
                PropertyValueRow(label: "Upload Limit:", value: UnitFormatter.limit(v.upLimit))
                PropertyValueRow(label: "Wasted:", value: size(v.totalWasted))
            }
            GridRow {
                PropertyValueRow(label: "Share Ratio:", value: ValueFormatter.ratio(v.shareRatio))
                PropertyValueRow(label: "Reannounce In:", value: DurationFormatter.string(v.reannounce))
                PropertyValueRow(label: "Last Seen Complete:", value: lastSeen)
            }
            GridRow {
                PropertyValueRow(label: "Popularity:", value: ValueFormatter.ratio(v.popularity),
                                 help: "Ratio / Time Active (in months), indicates how popular the torrent is")
            }
        }
    }

    private var timeActive: String {
        isFinished
            ? String(localized: "\(DurationFormatter.string(values.timeElapsed)) (seeded for \(DurationFormatter.string(values.seedingTime)))")
            : DurationFormatter.string(values.timeElapsed)
    }
}
