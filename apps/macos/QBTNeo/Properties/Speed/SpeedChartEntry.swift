import Foundation

/// One plotted value: a series at a point in time.
struct SpeedChartEntry: Identifiable {
    let id: Int
    let date: Date
    let value: Double
    let series: SpeedGraphSeries

    /// Flattens points into one entry per enabled series.
    static func entries(_ points: [SpeedPoint], series: [SpeedGraphSeries]) -> [Self] {
        var result: [Self] = []
        result.reserveCapacity(points.count * series.count)
        for line in series {
            for (index, point) in points.enumerated() {
                result.append(Self(id: line.rawValue * 1_000_000 + index, date: point.date, value: point.value(line), series: line))
            }
        }
        return result
    }
}
