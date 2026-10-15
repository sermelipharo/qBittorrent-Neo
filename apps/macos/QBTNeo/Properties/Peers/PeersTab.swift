import SwiftUI

/// Peers tab (features.md §2.5).
struct PeersTab: View {
    let item: TorrentItem
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui
    @SceneStorage("PeerListColumns") private var columns = TableColumnCustomization<PeerRow>()

    var body: some View {
        @Bindable var properties = model.properties
        let hideZero = gui.hideZeroValues && gui.hideZeroMode == .always
        Table(of: PeerRow.self, selection: $properties.peerSelection, sortOrder: $properties.peerSortOrder,
              columnCustomization: $columns) {
            TableColumn("Country/Region", value: \PeerRow.info.country) { row in
                Text(row.flag.isEmpty ? "–" : row.flag)
                    .help(row.info.country)
                    .accessibilityLabel(Text(row.info.country))
            }
            .width(min: 30, ideal: 40)
            .customizationID("country")
            .defaultVisibility(model.corePreferences.advanced.resolvePeerCountries ? .automatic : .hidden)
            TableColumn("IP/Address", value: \PeerRow.info.ip) { row in
                Text(row.info.hostName.isEmpty ? row.info.ip : row.info.hostName)
                    .help(row.info.ip)
                    .textSelection(.enabled)
            }
            .width(min: 80, ideal: 150)
            .customizationID("ip")
            TableColumn("Port", value: \PeerRow.info.port) { row in Text(String(row.info.port)).monospacedDigit() }
                .width(min: 36, ideal: 52).alignment(.trailing).customizationID("port")
            TableColumn("Connection", value: \PeerRow.info.connectionType) { row in Text(row.info.connectionType) }
                .width(min: 40, ideal: 70).customizationID("connection")
            TableColumn("Flags", value: \PeerRow.info.flags) { row in
                Text(row.info.flags).monospaced().help(row.info.flagsDescription)
            }
            .width(min: 40, ideal: 80)
            .customizationID("flags")
            TableColumn("Client", value: \PeerRow.info.client) { row in Text(row.info.client).help(row.info.client) }
                .width(min: 60, ideal: 150).customizationID("client")
            TableColumn("Peer ID Client", value: \PeerRow.info.peerIdClient) { row in Text(row.info.peerIdClient).monospaced() }
                .width(min: 60, ideal: 90).customizationID("peerID").defaultVisibility(.hidden)
            Group {
            TableColumn("Progress", value: \PeerRow.info.progress) { row in
                Text(ValueFormatter.percent(row.info.progress)).monospacedDigit()
            }
            .width(min: 44, ideal: 64).alignment(.trailing).customizationID("progress")
            TableColumn("Down Speed", value: \PeerRow.info.dlSpeed) { row in
                PeerValueText(value: row.info.dlSpeed, hideZero: hideZero, isSpeed: true)
            }
            .width(min: 50, ideal: 86).alignment(.trailing).customizationID("down")
            TableColumn("Up Speed", value: \PeerRow.info.upSpeed) { row in
                PeerValueText(value: row.info.upSpeed, hideZero: hideZero, isSpeed: true)
            }
            .width(min: 50, ideal: 86).alignment(.trailing).customizationID("up")
            TableColumn("Downloaded", value: \PeerRow.info.downloaded) { row in
                PeerValueText(value: row.info.downloaded, hideZero: hideZero)
            }
            .width(min: 50, ideal: 86).alignment(.trailing).customizationID("downloaded")
            TableColumn("Uploaded", value: \PeerRow.info.uploaded) { row in
                PeerValueText(value: row.info.uploaded, hideZero: hideZero)
            }
            .width(min: 50, ideal: 86).alignment(.trailing).customizationID("uploaded")
            TableColumn("Relevance", value: \PeerRow.info.relevance) { row in
                Text(ValueFormatter.percent(row.info.relevance)).monospacedDigit()
            }
            .width(min: 44, ideal: 70).alignment(.trailing).customizationID("relevance")
            TableColumn("Files", value: \PeerRow.info.files) { row in
                Text(row.info.files.replacing("\n", with: ";")).help(row.info.files)
            }
            .width(min: 60, ideal: 200)
            .customizationID("files")
            }
        } rows: {
            ForEach(properties.peers) { row in
                TableRow(row)
            }
        }
        .contextMenu(forSelectionType: String.self) { ids in
            PeerContextMenu(item: item, ids: ids)
        }
        .onCopyCommand {
            [NSItemProvider(object: model.selectedPeers(properties.peerSelection).map(\.endpoint).joined(separator: "\n") as NSString)]
        }
        .onDeleteCommand { model.requestBanPeers(properties.peerSelection) }
        .overlay { PropertiesFailureOverlay(tab: .peers, isEmpty: properties.peers.isEmpty) }
    }
}
