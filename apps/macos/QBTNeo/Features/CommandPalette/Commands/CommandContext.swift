import Foundation

/// What a command acts on: the app and the target torrents (the transfer-list
/// selection, or the torrent picked in the Command Palette). The selection
/// aggregates are computed once, on first use.
@MainActor
final class CommandContext {
    let model: AppModel
    let ids: [String]

    init(model: AppModel, ids: [String]) {
        self.model = model
        self.ids = ids
    }

    /// The transfer list's current selection.
    convenience init(selectionOf model: AppModel) {
        self.init(model: model, ids: model.list.selectedIDs)
    }

    private(set) lazy var selection = TorrentSelection(model: model, items: model.items(ids))

    var hasTargets: Bool { !ids.isEmpty }
}
