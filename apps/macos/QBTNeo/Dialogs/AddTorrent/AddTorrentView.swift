import SwiftUI

/// The "Add new torrent" dialog layout (features.md §3.1): the torrent's
/// name and size on top, the options on the left, its files on the right.
struct AddTorrentView: View {
    @Bindable var dialog: AddTorrentModel
    let onAccept: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            AddTorrentHeader(dialog: dialog)
                .padding(.horizontal, Design.Spacing.xLarge)
                .padding(.vertical, Design.Spacing.medium)
            Divider()
            HStack(spacing: 0) {
                AddTorrentOptionsForm(dialog: dialog)
                    .frame(width: 320)
                Divider()
                AddTorrentContentTree(dialog: dialog)
                    .frame(minWidth: 360)
            }
            Divider()
            AddTorrentFooter(dialog: dialog, onAccept: onAccept, onCancel: onCancel)
        }
        .frame(minWidth: Design.Window.addTorrentMinSize.width, minHeight: Design.Window.addTorrentMinSize.height)
    }
}
