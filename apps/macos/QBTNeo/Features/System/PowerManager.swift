import Foundation
import IOKit.pwr_mgt

/// Inhibits idle system sleep while torrents are busy (features.md
/// §4.10.6): any torrent moving; with "Inhibit system sleep when torrents
/// are downloading", any unfinished running torrent with metadata; with
/// "…seeding", any finished running torrent. Re-evaluated periodically.
@MainActor
final class PowerManager {
    private let app: AppModel
    private var assertionID: IOPMAssertionID = 0
    private var task: Task<Void, Never>?

    init(app: AppModel) {
        self.app = app
    }

    func start() {
        task = Task { [weak self] in
            while !Task.isCancelled {
                self?.evaluate()
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    func stop() {
        task?.cancel()
        setBusy(false)
    }

    private func evaluate() {
        let gui = app.gui
        let busy = app.transfers.items.contains { item in
            let state = item.state
            if state == .moving { return true }
            let running = !state.isStopped && !state.isErrored
            if gui.preventSuspendWhenDownloading, running, item.progress < 1, item.hasMetadata { return true }
            if gui.preventSuspendWhenSeeding, !state.isStopped, item.progress >= 1 { return true }
            return false
        }
        setBusy(busy)
    }

    private func setBusy(_ busy: Bool) {
        if busy, assertionID == 0 {
            let reason = "qBittorrent Neo is active" as CFString
            IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason, &assertionID)
        } else if !busy, assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
}
