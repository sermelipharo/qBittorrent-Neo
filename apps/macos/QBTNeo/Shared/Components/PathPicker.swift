import SwiftUI

/// Folder path field with a history menu and a "Browse…" button
/// (qBittorrent's `FileSystemPathComboEdit`).
struct PathPicker: View {
    let title: LocalizedStringKey
    @Binding var path: String
    var history: [String] = []
    /// Shown greyed when the field is empty (the effective default).
    var placeholder = ""
    @State private var isBrowsing = false

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            TextField(title, text: $path, prompt: Text(placeholder))
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .truncationMode(.head)
                .frame(minWidth: 180)
            if !history.isEmpty {
                Menu("History", systemImage: "clock.arrow.circlepath") {
                    ForEach(history, id: \.self) { entry in
                        Button(entry) { path = entry }
                    }
                }
                .labelStyle(.iconOnly)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Recently used paths")
            }
            Button("Browse…") { isBrowsing = true }
                .help("Browse…")
        }
        .fileImporter(isPresented: $isBrowsing, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { path = url.path(percentEncoded: false) }
        }
        .fileDialogDefaultDirectory(path.isEmpty ? nil : URL(filePath: path, directoryHint: .isDirectory))
    }
}
