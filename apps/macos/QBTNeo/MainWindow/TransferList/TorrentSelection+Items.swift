import Foundation

extension TorrentSelection {
    /// A selection of known items, visible or not (Command Palette targets).
    init(model: AppModel, items: [TorrentItem]) {
        self.model = model
        self.items = items
    }
}
