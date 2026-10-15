import SwiftUI

/// Trackers tab (features.md §2.4): DHT/PeX/LSD rows first, trackers with
/// expandable announce endpoints, tier buttons and the tracker context menu.
struct TrackersTab: View {
    let item: TorrentItem
    @Environment(AppModel.self) private var model
    @SceneStorage("TrackerListColumns") private var columns = TableColumnCustomization<TrackerRow>()

    var body: some View {
        @Bindable var properties = model.properties
        HStack(spacing: 0) {
            Table(of: TrackerRow.self, selection: $properties.trackerSelection, sortOrder: $properties.trackerSortOrder,
                  columnCustomization: $columns) {
                TableColumn("URL/Announce Endpoint", value: \.url) { row in
                    TrackerURLCell(row: row, properties: model.properties)
                }
                .width(min: 160, ideal: 320)
                .customizationID("url")
                TableColumn("Tier", value: \.tier) { row in
                    Text(row.kind == .tracker ? row.tier.formatted() : "").monospacedDigit()
                }
                .width(min: 30, ideal: 40)
                .alignment(.trailing)
                .customizationID("tier")
                TableColumn("BT Protocol", value: \.btVersion) { row in
                    Text(row.btVersion > 0 ? "v\(row.btVersion)" : "")
                }
                .width(min: 40, ideal: 70)
                .customizationID("protocol")
                .defaultVisibility(.hidden)
                TableColumn("Status", value: \.statusText) { row in
                    TrackerCountText(row: row, text: row.statusText, properties: model.properties)
                }
                .width(min: 70, ideal: 110)
                .customizationID("status")
                Group {
                TableColumn("Peers", value: \TrackerRow.peers) { row in
                    TrackerCountText(row: row, text: ValueFormatter.count(row.peers), properties: model.properties)
                }
                    .width(min: 40, ideal: 60).alignment(.trailing).customizationID("peers")
                TableColumn("Seeds", value: \TrackerRow.seeds) { row in
                    TrackerCountText(row: row, text: ValueFormatter.count(row.seeds), properties: model.properties)
                }
                    .width(min: 40, ideal: 60).alignment(.trailing).customizationID("seeds")
                TableColumn("Leeches", value: \TrackerRow.leeches) { row in
                    TrackerCountText(row: row, text: ValueFormatter.count(row.leeches), properties: model.properties)
                }
                    .width(min: 40, ideal: 60).alignment(.trailing).customizationID("leeches")
                TableColumn("Times Downloaded", value: \TrackerRow.downloaded) { row in
                    TrackerCountText(row: row, text: ValueFormatter.count(row.downloaded), properties: model.properties)
                }
                .width(min: 50, ideal: 110).alignment(.trailing).customizationID("downloaded")
                TableColumn("Message", value: \TrackerRow.message) { row in
                    TrackerCountText(row: row, text: row.message, properties: model.properties)
                }
                .width(min: 80, ideal: 240)
                .customizationID("message")
                TableColumn("Next Announce", value: \TrackerRow.nextAnnounce) { row in
                    TrackerCountText(row: row, text: DurationFormatter.string(max(row.nextAnnounce, 0), resolution: .seconds), properties: model.properties)
                }
                .width(min: 50, ideal: 100).alignment(.trailing).customizationID("next")
                TableColumn("Min Announce", value: \TrackerRow.minAnnounce) { row in
                    TrackerCountText(row: row, text: DurationFormatter.string(max(row.minAnnounce, 0), resolution: .seconds), properties: model.properties)
                }
                .width(min: 50, ideal: 100).alignment(.trailing).customizationID("min")
                }
            } rows: {
                ForEach(properties.trackerRows) { row in
                    TableRow(row)
                }
            }
            .contextMenu(forSelectionType: String.self) { ids in
                TrackerContextMenu(item: item, ids: ids)
            } primaryAction: { ids in
                model.requestEditTracker(hash: item.id, rowIDs: ids)
            }
            .onDeleteCommand { model.removeSelectedTrackers(hash: item.id) }
            .onCopyCommand { model.trackerURLProviders() }
            .overlay { PropertiesFailureOverlay(tab: .trackers, isEmpty: properties.trackerRows.isEmpty) }
            Divider()
            TrackerTierButtons(item: item)
        }
    }
}
