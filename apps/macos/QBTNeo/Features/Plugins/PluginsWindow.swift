import SwiftUI
import UniformTypeIdentifiers

/// "Plugins" (qBittorrent 5.3 `PluginsDialog`): installed Lua plugins with
/// enable toggles, install/update from local files, uninstall, invoke, and
/// the details of the selected plugin. While the global switch is off the
/// window explains it and links to the setting.
struct PluginsWindow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var model = PluginsModel()
    @State private var isPickingFiles = false
    /// Plugin selected when the window opens (snapshots).
    var initialSelection: String?

    static let invocableHelp =
        String(localized: "Plugin provides 'invoke' function that is called when user triggers corresponding plugin action from 'Plugins' menu.")

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            if model.status.running {
                engineContent
            } else {
                offContent
            }
            HStack {
                if model.status.running {
                    Button("Install/Update plugins") { isPickingFiles = true }
                    Button("Uninstall") { Task { await model.uninstall(model.selection) } }
                        .disabled(model.selection.isEmpty)
                    Button("Invoke") {
                        if let id = model.selectedPlugin?.id { Task { await model.invoke(id) } }
                    }
                    .disabled(!model.canInvoke)
                    .help(Self.invocableHelp)
                    if model.busy {
                        ProgressView().controlSize(.small)
                    }
                }
                Spacer()
                Button("Close") { dismissWindow(id: FeatureWindowID.plugins.rawValue) }
                    .keyboardShortcut(.cancelAction)
            }
            .disabled(model.busy)
        }
        .padding(Design.Spacing.xLarge)
        .frame(minWidth: 640, minHeight: 420)
        .navigationTitle(FeatureWindowID.plugins.title)
        .fileImporter(isPresented: $isPickingFiles, allowedContentTypes: [UTType(filenameExtension: "lua") ?? .sourceCode],
                      allowsMultipleSelection: true) { result in
            if case .success(let urls) = result { Task { await model.install(urls.map { $0.path(percentEncoded: false) }) } }
        }
        .fileDialogMessage(Text("Select plugins"))
        .alert(model.alert?.title ?? "", item: $model.alert) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
        .task(id: app.phase) {
            await model.attach(app.client)
            if let initialSelection, model.selection.isEmpty { model.selection = [initialSelection] }
        }
        .task {
            for await event in app.events() {
                if case .pluginsChanged = event { await model.reload() }
            }
        }
    }

    @ViewBuilder private var engineContent: some View {
        Text("Installed plugins:")
            .font(.headline)
        PluginsTable(model: model)
        if let plugin = model.selectedPlugin {
            PluginDetails(plugin: plugin)
        }
        ForEach(model.status.problems, id: \.self) { problem in
            Label(problem, systemImage: Symbol.exclamationmarkTriangleFill)
                .settingsFootnote()
                .symbolRenderingMode(.multicolor)
        }
        Text("An enabled plugin can run programs and send e-mail as you. Install plugins only from people you trust.")
            .settingsFootnote()
    }

    /// Off, or on but refused to start (`problems`: the plugins folder or a
    /// plugin file could be written by other users).
    private var offContent: some View {
        ContentUnavailableView {
            if model.status.problems.isEmpty {
                Label("Plugins are turned off", systemImage: Symbol.puzzlepieceExtension)
            } else {
                Label("Plugins were not started", systemImage: Symbol.exclamationmarkTriangleFill)
            }
        } description: {
            if model.status.problems.isEmpty {
                Text("Lua plugins can react to torrent events and run programs. Turn them on in Settings › Privacy to manage them here.")
            } else {
                Text(model.status.problems.joined(separator: "\n"))
                Text("Fix the permissions, then turn plugins off and on again.")
            }
        } actions: {
            Button("Open Settings…") { app.revealSetting("plugins_enabled") }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
