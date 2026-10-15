import SwiftUI

/// A path text field with a "Browse…" button and live validation, the
/// SwiftUI counterpart of qBittorrent's `FileSystemPathEdit`. An empty
/// field shows the effective default as a placeholder.
struct PathControl: View {
    let title: LocalizedStringKey
    @Binding var path: String
    var kind = PathKind.directory
    var placeholder: String?
    var panelMessage: String?
    var validates = true

    @State private var isImporting = false
    @State private var warning: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: Design.Spacing.tight) {
            HStack(spacing: Design.Spacing.small) {
                CommitTextField(title: title, text: $path, prompt: placeholder ?? String(localized: "Not set"), trims: true)
                    .labelsHidden()
                    .frame(minWidth: FeatureDesign.Width.pathField)
                Button("Browse…") { isImporting = true }
                    .help("Browse…")
            }
            if let warning {
                InlineMessage(text: warning, style: .warning)
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: kind.contentTypes, onCompletion: pick)
        .fileDialogMessage(panelMessage.map { Text($0) })
        .fileDialogDefaultDirectory(defaultDirectory)
        .task(id: path) { warning = validates ? kind.warning(for: path) : nil }
    }

    private var defaultDirectory: URL? {
        let current = path.isEmpty ? (placeholder ?? "") : path
        guard !current.isEmpty else { return nil }
        let url = URL(filePath: (current as NSString).expandingTildeInPath)
        if case .directory = kind { return url }
        return url.deletingLastPathComponent()
    }

    private func pick(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        path = url.path(percentEncoded: false)
    }
}
