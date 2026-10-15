import Foundation

/// One averaged point of the speed graph.
struct SpeedPoint: Identifiable, Equatable, Sendable {
    let id: Int64
    let date: Date
    /// Bytes/s for each `SpeedGraphSeries` raw value.
    let values: [Double]

    func value(_ series: SpeedGraphSeries) -> Double { values[series.rawValue] }

    /// Averages samples into buckets of `resolution` seconds (by timestamp),
    /// so a 24-hour period still draws at most ~600 points. The core already
    /// averages long periods, so samples may be further apart than 1 s.
    static func downsample(_ samples: [SpeedSample], resolution: Int) -> [Self] {
        guard !samples.isEmpty else { return [] }
        let step = Int64(max(resolution, 1))
        var points: [Self] = []
        points.reserveCapacity(samples.count / Int(step) + 1)
        var index = 0
        while index < samples.count {
            let bucketID = samples[index].timestampMs / 1_000 / step
            var end = index + 1
            while end < samples.count, samples[end].timestampMs / 1_000 / step == bucketID { end += 1 }
            let bucket = samples[index..<end]
            var sums = [Double](repeating: 0, count: SpeedGraphSeries.allCases.count)
            for sample in bucket {
                sums[0] += Double(sample.upload)
                sums[1] += Double(sample.download)
                sums[2] += Double(sample.payloadUpload)
                sums[3] += Double(sample.payloadDownload)
                sums[4] += Double(sample.overheadUpload)
                sums[5] += Double(sample.overheadDownload)
                sums[6] += Double(sample.dhtUpload)
                sums[7] += Double(sample.dhtDownload)
                sums[8] += Double(sample.trackerUpload)
                sums[9] += Double(sample.trackerDownload)
            }
            let count = Double(bucket.count)
            let last = bucket[bucket.endIndex - 1]
            points.append(Self(
                id: last.timestampMs, date: Date(timeIntervalSince1970: Double(last.timestampMs) / 1_000),
                values: sums.map { $0 / count }
            ))
            index = end
        }
        return points
    }
}
