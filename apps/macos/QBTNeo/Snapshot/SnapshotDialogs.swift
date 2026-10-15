import SwiftUI

/// Renders the Add Torrent dialog and the main-window sheets.
@MainActor
struct SnapshotDialogs {
    let renderer: SnapshotRenderer
    let model: AppModel
    let client: DemoClient

    func renderAll() async {
        // Add New Torrent with metadata, and a magnet still retrieving it.
        let ready = AddTorrentModel(source: .file(path: "/tmp/Elephants Dream (2006) [1080p].torrent"), client: client, app: model)
        ready.received(DemoState.sampleMetadata(for: .bytes(data: Data()), existing: [:]))
        ready.tags = ["favorite"]
        for appearance in SnapshotAppearance.allCases {
            await renderer.render(addTorrent(ready), size: Design.Window.addTorrentDefaultSize, name: "add-torrent", appearance: appearance)
        }
        let magnet = AddTorrentModel(
            source: .url(url: "magnet:?xt=urn:btih:\(DemoRandom.hex("magnet", length: 40))&dn=Tears+of+Steel+(2012)"),
            client: client, app: model
        )
        await renderer.render(addTorrent(magnet), size: Design.Window.addTorrentDefaultSize, name: "add-torrent-magnet", appearance: .light)

        let ids = model.list.selectedIDs
        let sheets: [(String, MainSheet)] = [
            ("dialog-remove", .removeTorrents(ids: ids, deleteFiles: false)),
            ("dialog-speed-limits", .speedLimits),
            ("dialog-torrent-options", .torrentOptions(ids: ids)),
            ("dialog-edit-trackers", .editTrackers(ids: ids)),
            ("dialog-add-links", .addLinks(initialText: "magnet:?xt=urn:btih:\(DemoRandom.hex("x", length: 40))&dn=Example\n")),
            ("dialog-category", .category(CategoryEditorRequest(mode: .new(parent: "Movies")))),
            ("dialog-rename", .textPrompt(TextPromptRequest(
                title: String(localized: "Rename"), label: String(localized: "New name:"), text: "Sintel (2010) [4K]",
                purpose: .renameTorrent(id: ids.first ?? "")
            ))),
            ("dialog-add-peers", .addPeers(ids: ids)),
        ]
        for (name, sheet) in sheets {
            let view = MainSheetContent(sheet: sheet)
                .environment(model)
                .environment(model.gui)
            await renderer.render(view, size: CGSize(width: 620, height: 700), name: name, appearance: .light, fitHeight: true)
        }
    }

    private func addTorrent(_ dialog: AddTorrentModel) -> some View {
        AddTorrentView(dialog: dialog, onAccept: {}, onCancel: {})
            .environment(model)
            .environment(model.gui)
    }
}
