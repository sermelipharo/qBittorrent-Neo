import Charts
import SwiftUI

/// Line chart of the enabled speed series; upload blue, download green,
/// qBittorrent's dash patterns per series family.
struct SpeedChart: View {
    let points: [SpeedPoint]
    let series: Set<SpeedGraphSeries>

    var body: some View {
        let enabled = SpeedGraphSeries.allCases.filter(series.contains)
        let entries = SpeedChartEntry.entries(points, series: enabled)
        Chart(entries) { entry in
            LineMark(
                x: .value("Time", entry.date),
                y: .value("Speed", entry.value),
                series: .value("Series", entry.series.title)
            )
            .foregroundStyle(by: .value("Series", entry.series.title))
            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: entry.series.dash))
        }
        .chartForegroundStyleScale(domain: enabled.map(\.title), range: enabled.map(\.color))
        .chartLegend(position: .top, alignment: .leading)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                AxisValueLabel {
                    Text(UnitFormatter.speed(Int64(value.as(Double.self) ?? 0)))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 6)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .accessibilityLabel(Text("Speed graph"))
        .overlay {
            if points.isEmpty {
                ContentUnavailableView("No Data Yet", systemImage: Symbol.chartXyaxisLine)
            }
        }
    }
}
