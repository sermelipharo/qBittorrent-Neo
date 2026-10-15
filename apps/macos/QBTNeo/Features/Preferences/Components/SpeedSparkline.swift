import Charts
import SwiftUI

/// The last minute of download and upload speed with the current download
/// limit as a dashed line (Speed pane header).
struct SpeedSparkline: View {
    let points: [SpeedPoint]
    /// Effective download limit in bytes/s (0 = unlimited, not drawn).
    let downloadLimit: Int64

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(x: .value("Time", point.date), y: .value("Speed", point.value(.download)), series: .value("Series", "download"))
                    .foregroundStyle(SpeedGraphSeries.download.color)
                LineMark(x: .value("Time", point.date), y: .value("Speed", point.value(.upload)), series: .value("Series", "upload"))
                    .foregroundStyle(SpeedGraphSeries.upload.color)
            }
            if downloadLimit > 0 {
                RuleMark(y: .value("Limit", Double(downloadLimit)))
                    .foregroundStyle(SpeedGraphSeries.download.color.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartYScale(domain: 0...max(peak, 1))
        .accessibilityLabel(Text("Speed in the last minute"))
    }

    private var peak: Double {
        let speeds = points.flatMap { [$0.value(.download), $0.value(.upload)] }
        return max(speeds.max() ?? 0, Double(downloadLimit)) * 1.1
    }
}
