import SwiftUI

/// Window hosting one "Add new torrent" dialog (one window per torrent, like
/// qBittorrent on macOS). Closing the window cancels metadata retrieval.
struct AddTorrentWindow: View {
    let dialogID: UUID?
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let dialogID, let dialog = model.addDialog(dialogID) {
                AddTorrentView(dialog: dialog, onAccept: {
                    model.accept(dialogID)
                    dismiss()
                }, onCancel: {
                    model.closeAddDialog(dialogID)
                    dismiss()
                })
                .navigationTitle(dialog.title)
                .onChange(of: dialog.phase) { _, phase in
                    if phase == .duplicate { dismiss() }
                }
            } else {
                ContentUnavailableView("Nothing to Add", systemImage: Symbol.docBadgePlus)
                    .frame(width: 400, height: 240)
            }
        }
        .onDisappear {
            if let dialogID { model.closeAddDialog(dialogID) }
        }
    }
}
