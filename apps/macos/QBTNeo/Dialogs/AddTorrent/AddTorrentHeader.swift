import SwiftUI

/// Top of the Add Torrent dialog: the torrent's name, the size to download
/// and the free space, and the torrent information (date, hashes, comment)
/// behind an info button.
struct AddTorrentHeader: View {
    let dialog: AddTorrentModel
    @State private var showsInfo = false

    var body: some View {
        let name = dialog.metadata?.name ?? dialog.title
        HStack(spacing: Design.Spacing.regular) {
            Image(systemName: Symbol.docBadgePlus)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(.tint.opacity(0.14), in: .rect(cornerRadius: Design.Radius.large))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                Text(name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .help(name)
                HStack(spacing: Design.Spacing.small) {
                    status
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Torrent Information", systemImage: Symbol.infoCircle) { showsInfo.toggle() }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .font(.title3)
                .foregroundStyle(.secondary)
                .help("Torrent information")
                .popover(isPresented: $showsInfo, arrowEdge: .bottom) {
                    AddTorrentInfoPanel(dialog: dialog)
                        .padding(Design.Spacing.medium)
                        .frame(width: 420)
                }
        }
    }

    @ViewBuilder private var status: some View {
        switch dialog.phase {
        case .failed(let message):
            Label(message, systemImage: Symbol.exclamationmarkTriangle)
                .foregroundStyle(.red)
                .lineLimit(1)
                .help(message)
        default:
            if dialog.hasMetadata {
                Text(dialog.sizeSummary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                ProgressView().controlSize(.mini)
                Text("Retrieving metadata…")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
