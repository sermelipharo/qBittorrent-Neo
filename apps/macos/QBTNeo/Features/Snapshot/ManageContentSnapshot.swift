import SwiftUI

/// The Manage Torrent Content dialog for the demo torrent with the most
/// files, with a few files selected and two paths edited
/// (`--snapshot-only manage-content`).
struct ManageContentSnapshot: View {
    let model: AppModel
    @State private var dialog: ManageContentModel?

    var body: some View {
        Group {
            if let dialog {
                ManageContentSheet(dialog: dialog)
            } else {
                Color.clear
            }
        }
        .task { await prepare() }
    }

    private func prepare() async {
        guard let client = model.client else { return }
        let candidates = model.transfers.items.filter(\.hasMetadata)
        var best: (item: TorrentItem, files: [TorrentFile])?
        for item in candidates {
            let files = (try? client.files(hash: item.id, indexes: [])) ?? []
            if files.count > (best?.files.count ?? 0) { best = (item, files) }
        }
        guard let best else { return }
        let selected = best.files.prefix(4).map(\.index)
        let prepared = ManageContentModel(app: model, id: best.item.id, torrentName: best.item.name, selectedFiles: Array(selected))
        await prepared.load()
        for file in best.files.prefix(2) {
            let name = (file.name as NSString).lastPathComponent
            let renamed = (file.name as NSString).deletingLastPathComponent + "/Renamed - " + name
            prepared.setPath(renamed, forFile: file.index)
        }
        dialog = prepared
    }
}
