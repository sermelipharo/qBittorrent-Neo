import Foundation
import Synchronization

/// Demo state of the auxiliary features (RSS, search, torrent creator,
/// cookies) used by the `DemoClient` feature extensions. It lives outside
/// `DemoState` so those features stay self-contained; one store is shared by
/// every demo client in the process.
final class DemoFeatureStore: Sendable {
    static let shared = DemoFeatureStore()

    let rss = Mutex(DemoRSSState())
    let search = Mutex(DemoSearchState())
    let creator = Mutex(DemoCreatorState())
    let cookies = Mutex(DemoAppCatalog.cookies)
    /// Snapshot mode: searches and creator tasks complete immediately.
    let isInstant = Mutex(false)

    /// Seconds since `start`, or "long ago" in instant mode.
    func elapsed(since start: Date) -> Double {
        isInstant.withLock { $0 } ? 3_600 : Date.now.timeIntervalSince(start)
    }
}
