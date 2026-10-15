import SwiftUI

/// The transfer-list context menu (features.md §1.8), with entries shown,
/// enabled and checked according to the whole selection.
struct TransferContextMenu: View {
    let selection: TorrentSelection
    @Environment(AppModel.self) private var model

    var body: some View {
        let ids = selection.ids
        if selection.needsStart {
            Button("Start", systemImage: Symbol.playFill) { model.start(ids) }
        }
        if selection.needsStop {
            Button("Stop", systemImage: Symbol.pauseFill) { model.stop(ids) }
        }
        if selection.needsForce {
            Button("Force Start", systemImage: Symbol.forwardFill) { model.forceStart(ids) }
        }
        Divider()
        Button("Remove", systemImage: Symbol.trash) { model.requestRemove(ids) }
        Divider()
        Button("Set Location…", systemImage: Symbol.folder) { model.requestSetLocation(ids) }
        if ids.count == 1 {
            Button("Rename…", systemImage: Symbol.pencil) { model.requestRename(ids[0]) }
        }
        Button("Edit Trackers…", systemImage: Symbol.antennaRadiowavesLeftAndRight) { model.sheet = .editTrackers(ids: ids) }
        TransferCategoryMenu(selection: selection)
        TransferTagsMenu(selection: selection)
        Toggle("Automatic Torrent Management", isOn: selection.autoTMMBinding)
            .help("Automatic mode means that various torrent properties (e.g. save path) will be decided by the associated category")
        Divider()
        Button("Torrent Options…", systemImage: Symbol.sliderHorizontal3) { model.sheet = .torrentOptions(ids: ids) }
        if selection.allFinishedWithMetadata {
            Toggle("Super Seeding Mode", sources: selection.superSeedingSources, isOn: \.self)
        }
        Divider()
        if selection.hasMetadata {
            Button("Preview File…", systemImage: Symbol.eye) { model.requestPreview(ids[0]) }
        }
        if selection.hasUnfinished {
            Toggle("Download in Sequential Order", sources: selection.sequentialSources, isOn: \.self)
            Toggle("Download First and Last Pieces First", sources: selection.firstLastSources, isOn: \.self)
        }
        Divider()
        if selection.hasMetadata {
            Button("Force Recheck", systemImage: Symbol.arrowTrianglehead2ClockwiseRotate90) { model.requestRecheck(ids) }
        }
        Button("Force Reannounce", systemImage: Symbol.arrowClockwise) { model.reannounce(ids) }
            .disabled(!selection.canReannounce)
            .help(selection.canReannounce ? "" : "Can not force reannounce if torrent is Stopped/Queued/Errored/Checking")
        Divider()
        Button("Open Destination Folder", systemImage: Symbol.folderBadgeGearshape) { model.openDestination(ids) }
        if model.queueingEnabled, selection.hasUnfinished {
            Menu("Queue", systemImage: Symbol.listNumber) {
                Button("Move to Top", systemImage: Symbol.arrowUpToLine) { model.queue(ids, .top) }
                Button("Move Up", systemImage: Symbol.chevronUp) { model.queue(ids, .up) }
                Button("Move Down", systemImage: Symbol.chevronDown) { model.queue(ids, .down) }
                Button("Move to Bottom", systemImage: Symbol.arrowDownToLine) { model.queue(ids, .bottom) }
            }
        }
        Menu("Copy", systemImage: Symbol.docOnDoc) {
            ForEach(CopyKind.allCases, id: \.self) { kind in
                Button(kind.title) { model.copy(kind, ids: ids) }
                    .disabled(kind == .infohashV1 && !selection.hasInfohashV1 || kind == .infohashV2 && !selection.hasInfohashV2)
            }
        }
        Button("Export .torrent…", systemImage: Symbol.squareAndArrowUp) { model.requestExport(ids) }
            .help("Exported torrent is not necessarily the same as the imported")
    }
}
