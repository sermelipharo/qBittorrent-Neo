import SwiftUI

/// Shown over the content tree until metadata arrives (magnets), or when
/// retrieval failed.
struct AddTorrentMetadataState: View {
    let dialog: AddTorrentModel

    var body: some View {
        switch dialog.phase {
        case .failed(let message):
            ContentUnavailableView {
                Label("Cannot Read Torrent", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            }
        default:
            VStack(spacing: Design.Spacing.medium) {
                ProgressView()
                    .controlSize(.large)
                Text("Retrieving metadata…")
                    .font(.headline)
                Text("The file list appears as soon as peers send the torrent's metadata. You can already add it.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
        }
    }
}
