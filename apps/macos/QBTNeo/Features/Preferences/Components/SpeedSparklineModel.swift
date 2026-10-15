import Foundation
import Observation

/// The last minute of global download/upload speed for the Speed pane's
/// header, read from the core's existing speed history (no timer of its own:
/// the view refreshes it when the session status changes).
@Observable @MainActor
final class SpeedSparklineModel {
    nonisolated static let seconds: UInt32 = 60
    private(set) var points: [SpeedPoint] = []

    func refresh(client: (any CoreClient)?) async {
        guard let client else { return }
        let samples = await CoreCall.run { client.speedHistory(seconds: Self.seconds) }
        let points = SpeedPoint.downsample(samples, resolution: 1)
        if points != self.points { self.points = points }
    }
}
