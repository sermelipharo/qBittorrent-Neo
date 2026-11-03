import SwiftUI

/// "Python executable:" with a clear button and a file picker. Empty means
/// the bundled Python (or auto detection).
struct PythonPathField: View {
    @Binding var path: String
    @State private var isPicking = false

    var body: some View {
        LabeledContent(SettingsCatalog.key("python_executable_path")) {
            HStack(spacing: Design.Spacing.small) {
                CommitTextField(title: SettingsCatalog.key("python_executable_path"), text: $path,
                                prompt: String(localized: "(Auto detect if empty)"), trims: true)
                    .labelsHidden()
                    .frame(minWidth: FeatureDesign.Width.pathField)
                Button("Clear", systemImage: Symbol.xmark) { path = "" }
                    .labelStyle(.iconOnly)
                    .help("Clear")
                    .disabled(path.isEmpty)
                Button("Browse…") { isPicking = true }
                    .help("Browse…")
            }
        }
        .fileImporter(isPresented: $isPicking, allowedContentTypes: [.item]) { result in
            if case .success(let url) = result { path = url.path(percentEncoded: false) }
        }
        .fileDialogBrowserOptions(.includeHiddenFiles)
        .fileDialogDefaultDirectory(defaultDirectory)
    }

    /// Conda and venv interpreters live in hidden folders, hence the hidden files.
    private var defaultDirectory: URL? {
        guard !path.isEmpty else { return nil }
        return URL(filePath: (path as NSString).expandingTildeInPath).deletingLastPathComponent()
    }
}
