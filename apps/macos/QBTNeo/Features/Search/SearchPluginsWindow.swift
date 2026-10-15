import SwiftUI
import UniformTypeIdentifiers

/// "Search plugins" (features.md §3.23): installed plugins with enable
/// toggles, install from a file or URL, uninstall and update checks.
struct SearchPluginsWindow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var model = SearchPluginsModel()
    @State private var isPickingFiles = false
    @State private var isEnteringURL = false

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text("Installed search plugins:")
                .font(.headline)
            SearchPluginsTable(model: model)
            Text("Warning: Be sure to comply with your country's copyright laws when downloading torrents from any of these search engines.")
                .settingsFootnote()
            HStack(spacing: Design.Spacing.tight) {
                Text("You can get new search engine plugins here:")
                Link("https://plugins.qbittorrent.org", destination: PreferenceLinks.searchPlugins)
            }
            .font(.callout)
            HStack {
                Menu("Install a new one") {
                    Button("Local file…") { isPickingFiles = true }
                    Button("Web link…") { isEnteringURL = true }
                }
                .fixedSize()
                Button("Check for updates") { Task { await model.checkForUpdates() } }
                if model.busy {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                Button("Close") { dismissWindow(id: FeatureWindowID.searchPlugins.rawValue) }
                    .keyboardShortcut(.cancelAction)
            }
            .disabled(model.busy)
        }
        .padding(Design.Spacing.xLarge)
        .frame(minWidth: 620, minHeight: 380)
        .navigationTitle(FeatureWindowID.searchPlugins.title)
        .fileImporter(isPresented: $isPickingFiles, allowedContentTypes: [UTType(filenameExtension: "py") ?? .pythonScript],
                      allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { Task { await model.install(urls.map { $0.path(percentEncoded: false) }) } }
        }
        .fileDialogMessage(Text("Select search plugins"))
        .sheet(isPresented: $isEnteringURL) {
            PluginURLSheet { url in Task { await model.install([url]) } }
        }
        .alert(model.alert?.title ?? "", item: $model.alert) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
        .task(id: app.phase) { await model.attach(app.client) }
    }
}
