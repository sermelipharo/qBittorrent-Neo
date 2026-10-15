import SwiftUI

/// Peers tab context menu (features.md §2.5.3).
struct PeerContextMenu: View {
    let item: TorrentItem
    let ids: Set<String>
    @Environment(AppModel.self) private var model

    var body: some View {
        let reason = model.addPeersDisabledReason(item)
        Button("Add Peers…", systemImage: "person.badge.plus") { model.requestAddPeers(item) }
            .disabled(reason != nil)
            .help(reason ?? "")
        Button("Copy IP:port", systemImage: "doc.on.doc") { model.copyPeers(ids) }
            .disabled(ids.isEmpty)
            .help(ids.isEmpty ? "No peer was selected" : "")
        Divider()
        Button("Ban Peer Permanently", systemImage: "nosign") { model.requestBanPeers(ids) }
            .disabled(ids.isEmpty)
            .help(ids.isEmpty ? "No peer was selected" : "")
    }
}
