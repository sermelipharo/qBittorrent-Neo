import SwiftUI

/// The "Add new torrent" dialog layout (features.md §3.1): options on the
/// left, torrent information and content tree on the right.
struct AddTorrentView: View {
    @Bindable var dialog: AddTorrentModel
    let onAccept: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                AddTorrentOptionsForm(dialog: dialog)
                    .frame(width: 360)
                Divider()
                VStack(alignment: .leading, spacing: 0) {
                    AddTorrentInfoPanel(dialog: dialog)
                        .padding(Design.Spacing.medium)
                    Divider()
                    AddTorrentContentTree(dialog: dialog)
                }
                .frame(minWidth: 380)
            }
            Divider()
            AddTorrentFooter(dialog: dialog, onAccept: onAccept, onCancel: onCancel)
        }
        .frame(minWidth: Design.Window.addTorrentMinSize.width, minHeight: Design.Window.addTorrentMinSize.height)
    }
}
