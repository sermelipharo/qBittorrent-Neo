import AppKit
import Observation

/// Keeps the Dock tile speed badge in sync with the session rates while
/// "Show speed in Dock" is enabled; redraws only when the text changes.
@MainActor
final class DockBadgeController {
    private let model: AppModel
    private let view = DockBadgeView()
    private var task: Task<Void, Never>?

    init(model: AppModel) {
        self.model = model
        task = Task { [weak self] in
            guard let model = self?.model else { return }
            let values = Observations {
                (model.gui.showSpeedInDock, model.status.downloadRate, model.status.uploadRate)
            }
            for await (enabled, down, up) in values {
                self?.update(enabled: enabled, download: down, upload: up)
            }
        }
    }

    private func update(enabled: Bool, download: Int64, upload: Int64) {
        let tile = NSApp.dockTile
        let down = enabled && download > 0 ? "↓ " + UnitFormatter.compact(download) : nil
        let up = enabled && upload > 0 ? "↑ " + UnitFormatter.compact(upload) : nil
        guard down != view.downloadText || up != view.uploadText || tile.contentView == nil else { return }
        view.downloadText = down
        view.uploadText = up
        if down == nil, up == nil {
            tile.contentView = nil
        } else {
            view.frame = NSRect(origin: .zero, size: tile.size)
            tile.contentView = view
        }
        tile.display()
    }
}
