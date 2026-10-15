import SwiftUI

/// "Remove torrent(s)" confirmation (features.md §3.28): optional content
/// removal with "Remember choice"; Cancel is the default button.
struct RemoveTorrentsSheet: View {
    let ids: [String]
    @State private var deleteFiles: Bool
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    init(ids: [String], deleteFiles: Bool) {
        self.ids = ids
        _deleteFiles = State(initialValue: deleteFiles)
    }

    var body: some View {
        let stored = model.corePreferences.behavior.deleteTorrentContentFiles
        DialogContainer(title: "Remove torrent(s)", confirmTitle: "Remove", confirmRole: .destructive, cancelIsDefault: true) {
            model.remove(ids, deleteFiles: deleteFiles)
            dismiss()
        } content: {
            HStack(alignment: .top, spacing: Design.Spacing.medium) {
                Image(systemName: Symbol.exclamationmarkTriangleFill)
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                    Text(message)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Toggle("Also remove the content files", isOn: $deleteFiles)
                        Button("Remember choice", systemImage: Symbol.lock) { model.setDeleteFilesByDefault(deleteFiles) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .disabled(deleteFiles == stored)
                            .help("Remember choice")
                    }
                }
            }
        }
    }

    private var message: String {
        if ids.count == 1, let name = model.transfers.item(ids[0])?.name {
            return String(localized: "Are you sure you want to remove '\(name)' from the transfer list?")
        }
        return String(localized: "Are you sure you want to remove these \(ids.count) torrents from the transfer list?")
    }
}
