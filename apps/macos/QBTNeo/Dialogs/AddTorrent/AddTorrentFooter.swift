import SwiftUI

/// Bottom row: "Never show again", metadata status, "Save as .torrent file…",
/// Cancel / OK.
struct AddTorrentFooter: View {
    @Bindable var dialog: AddTorrentModel
    let onAccept: () -> Void
    let onCancel: () -> Void
    @State private var exportsTorrent = false

    var body: some View {
        HStack(spacing: Design.Spacing.medium) {
            Toggle("Never show again", isOn: $dialog.neverShowAgain)
            Spacer()
            if dialog.isMagnet {
                if dialog.hasMetadata {
                    Label("Metadata retrieval complete", systemImage: Symbol.checkmarkCircle)
                        .foregroundStyle(.secondary)
                } else if dialog.phase == .retrievingMetadata {
                    ProgressView().controlSize(.small)
                    Text("Retrieving metadata…").foregroundStyle(.secondary)
                }
            }
            if dialog.hasMetadata {
                Button("Save as .torrent file…") { exportsTorrent = true }
                    .disabled(!dialog.canSaveTorrentFile)
                    .help(dialog.canSaveTorrentFile ? "" : "Cannot create v2 torrent until its data is fully downloaded.")
            }
            Button("Cancel", role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)
            Button("Add", action: onAccept)
                .keyboardShortcut(.defaultAction)
                .disabled(dialog.phase != .ready && dialog.phase != .retrievingMetadata)
        }
        .padding(Design.Spacing.medium)
        .fileExporter(isPresented: $exportsTorrent, document: dialog.torrentDocument,
                      contentType: .torrent, defaultFilename: dialog.title) { _ in }
    }
}
