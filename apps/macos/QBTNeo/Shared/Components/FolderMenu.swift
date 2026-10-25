import SwiftUI

/// A folder chosen from a pop-up menu, like the download location in
/// Safari's settings: the folder's name with its icon, the recently used
/// paths, and "Choose Folder…". The full path is the tooltip.
struct FolderMenu: View {
    let title: LocalizedStringKey
    @Binding var path: String
    var history: [String] = []

    @State private var isBrowsing = false

    var body: some View {
        Menu {
            let recent = history.filter { $0 != path }
            if !path.isEmpty {
                Button(path) {}
                    .disabled(true)
            }
            if !recent.isEmpty {
                Section("Recently used paths") {
                    ForEach(recent, id: \.self) { entry in
                        Button(entry) { path = entry }
                    }
                }
            }
            Divider()
            Button("Choose Folder…") { isBrowsing = true }
        } label: {
            Label(Self.displayName(path), systemImage: Symbol.folder)
        }
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(path))
        .help(path)
        .fileImporter(isPresented: $isBrowsing, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { path = url.path(percentEncoded: false) }
        }
        .fileDialogDefaultDirectory(path.isEmpty ? nil : URL(filePath: path, directoryHint: .isDirectory))
    }

    /// The folder's name, or "/" for the root.
    static func displayName(_ path: String) -> String {
        let name = (path as NSString).lastPathComponent
        return name.isEmpty ? path : name
    }
}
