import SwiftUI

/// The transfer list: every qBittorrent column (show/hide/reorder persisted),
/// sorting by any column, multi-selection, context menu, double-click action,
/// drag to sidebar categories/tags, and drops of .torrent files and links.
struct TransferTable: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui
    @SceneStorage("TransferListColumns") private var columns = TableColumnCustomization<TorrentItem>()

    var body: some View {
        @Bindable var list = model.list
        Table(of: TorrentItem.self, selection: $list.selection, sortOrder: $list.sortOrder, columnCustomization: $columns) {
            TableColumnForEach(TransferColumn.allCases, id: \.self) { column in
                TableColumn(column.title, sortUsing: TransferSort(column)) { item in
                    TransferCell(item: item, column: column, gui: gui)
                }
                .width(min: column == .queuePosition ? 24 : 40, ideal: column.idealWidth)
                .alignment(column.isNumeric ? .trailing : .leading)
                .customizationID(column.rawValue)
                .defaultVisibility(column.isVisibleByDefault ? .automatic : .hidden)
            }
        } rows: {
            ForEach(list.visibleItems) { item in
                TableRow(item)
                    .draggable(TorrentDragPayload.encode(model.dragIDs(startingAt: item.id)))
            }
        }
        .contextMenu(forSelectionType: String.self) { ids in
            if !ids.isEmpty {
                TransferContextMenu(selection: TorrentSelection(model: model, ids: ids))
            }
        } primaryAction: { ids in
            model.performDoubleClick(Array(ids))
        }
        .alternatingRowBackgrounds(gui.alternatingRowColors ? .enabled : .disabled)
        .onDeleteCommand { model.requestRemove(list.selectedIDs) }
        .onKeyPress(.delete, phases: .down) { press in
            guard press.modifiers.contains(.shift) else { return .ignored }
            model.requestRemove(list.selectedIDs, deleteFiles: true)
            return .handled
        }
        .onKeyPress(KeyEquivalent(Character(UnicodeScalar(UInt16(NSF2FunctionKey)) ?? " "))) {
            guard list.selection.count == 1, let id = list.selection.first else { return .ignored }
            model.requestRename(id)
            return .handled
        }
        .onPasteCommand(of: [.utf8PlainText, .fileURL]) { _ in
            model.pasteFromClipboard()
        }
        .dropDestination(for: DroppedItem.self) { items, _ in
            _ = model.handleDrop(items)
        }
        .onChange(of: model.queueingEnabled, initial: true) { _, enabled in
            columns[visibility: TransferColumn.queuePosition.rawValue] = enabled ? .automatic : .hidden
        }
        .overlay {
            if list.visibleItems.isEmpty, model.phase == .running {
                TransferListEmptyView(isFiltering: !model.transfers.items.isEmpty)
            }
        }
        .accessibilityLabel(Text("Transfers"))
    }
}
