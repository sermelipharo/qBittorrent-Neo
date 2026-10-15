import Foundation

/// One plotted value: a series at a point in time.
struct SpeedChartEntry: Identifiable {
    /// Stable across refreshes (the point's timestamp and the series), so the
    /// chart only diffs the points that were added or dropped.
    let id: Int64
    let date: Date
    let value: Double
    let series: SpeedGraphSeries
    /// The series' localized title, looked up once per series and refresh.
    let title: String

    /// Flattens points into one entry per enabled series.
    static func entries(_ points: [SpeedPoint], series: [SpeedGraphSeries]) -> [Self] {
        var result: [Self] = []
        result.reserveCapacity(points.count * series.count)
        for line in series {
            let title = line.title
            for point in points {
                result.append(Self(
                    id: point.id &* 16 &+ Int64(line.rawValue), date: point.date, value: point.value(line), series: line, title: title
                ))
            }
        }
        return result
    }
}
