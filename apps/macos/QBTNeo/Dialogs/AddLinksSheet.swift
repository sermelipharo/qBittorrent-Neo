import SwiftUI

/// "Download from URLs" (features.md §3.3): one link per line, prefilled
/// from the clipboard.
struct AddLinksSheet: View {
    let initialText: String
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var showsEmptyWarning = false

    var body: some View {
        DialogContainer(title: "Add Torrent Links", confirmTitle: "Download", width: Design.Window.wideDialogWidth, onConfirm: submit) {
            Text("One link per line (HTTP links, Magnet links and info-hashes are supported)")
                .foregroundStyle(.secondary)
            TrackerListEditor(text: $text, minHeight: 180)
                .accessibilityLabel(Text("Torrent links"))
            if showsEmptyWarning {
                Label("Please type at least one URL.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(TorrentState.error.color)
            }
        }
        .onAppear { text = initialText }
    }

    private func submit() {
        guard text.split(whereSeparator: \.isNewline).contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            showsEmptyWarning = true
            return
        }
        model.addLinks(text)
        dismiss()
    }
}
