import SwiftUI

/// One watched folder: icon, path, recursive badge, Options… and Remove.
struct WatchedFolderRow: View {
    let folder: WatchedFolder
    let options: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(spacing: Design.Spacing.regular) {
            Label {
                Text(folder.path)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(folder.path)
            } icon: {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
            }
            if folder.recursive {
                Text("Recursive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Design.Spacing.small)
                    .background(.quaternary, in: .capsule)
            }
            Spacer()
            Button("Options…", action: options)
            Button("Remove", systemImage: "minus.circle", role: .destructive, action: remove)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Remove")
        }
    }
}
