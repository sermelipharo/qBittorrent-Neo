import SwiftUI

/// Content of the main window's sheets.
struct MainSheetContent: View {
    let sheet: MainSheet

    var body: some View {
        switch sheet {
        case .addLinks(let text): AddLinksSheet(initialText: text)
        case .removeTorrents(let ids, let deleteFiles): RemoveTorrentsSheet(ids: ids, deleteFiles: deleteFiles)
        case .speedLimits: SpeedLimitsSheet()
        case .torrentOptions(let ids): TorrentOptionsSheet(ids: ids)
        case .editTrackers(let ids): EditTrackersSheet(ids: ids)
        case .addTrackers(let id): AddTrackersSheet(id: id)
        case .addPeers(let ids): AddPeersSheet(ids: ids)
        case .category(let request): CategoryEditorSheet(request: request)
        case .tagEditor(let request): TagEditorSheet(request: request)
        case .textPrompt(let request): TextPromptSheet(request: request)
        case .preview(let id): PreviewSheet(id: id)
        case .lockPassword(let lockAfterSaving): LockPasswordSheet(lockAfterSaving: lockAfterSaving)
        }
    }
}
