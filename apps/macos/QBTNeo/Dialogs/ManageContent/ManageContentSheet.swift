import SwiftUI

/// "Manage Torrent Content" (qBittorrent 5.3, `TorrentContentLayoutDialog`,
/// features.md §3.38): the torrent's files with their full paths. Paths are
/// edited in place (click a path) or, for the selected files, through
/// "Common path:". Apply renames the changed files and keeps the dialog open;
/// Close discards what was not applied.
struct ManageContentSheet: View {
    let dialog: ManageContentModel
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var dialog = dialog
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            VStack(alignment: .leading, spacing: Design.Spacing.hairline) {
                Text("Manage Torrent Content")
                    .font(.headline)
                Text(dialog.torrentName)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            ManageContentTable(dialog: dialog)
                .frame(minHeight: 200)
                .clipShape(.rect(cornerRadius: Design.Radius.small))
                .overlay {
                    RoundedRectangle(cornerRadius: Design.Radius.small)
                        .strokeBorder(.separator)
                }
            HStack(spacing: Design.Spacing.regular) {
                Text("Common path:")
                    .foregroundStyle(dialog.hasCommonPath ? .primary : .tertiary)
                TextField("Common path:", text: $dialog.commonPath)
                    .labelsHidden()
                    .disabled(!dialog.hasCommonPath)
            }
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                Button("Apply") {
                    Task { await dialog.apply() }
                }
                .disabled(!dialog.canApply)
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(minWidth: 560, idealWidth: 720, maxWidth: .infinity, minHeight: 380, idealHeight: 480, maxHeight: .infinity)
        .onExitCommand { dismiss() }
        .task { await dialog.load() }
        .onChange(of: model.transfers.item(dialog.id) == nil) { _, removed in
            if removed { dismiss() }
        }
        .alert("Rename error", isPresented: $dialog.showsRenameError) {
            Button("OK") {}
        } message: {
            Text(dialog.renameErrorMessage)
        }
    }
}
