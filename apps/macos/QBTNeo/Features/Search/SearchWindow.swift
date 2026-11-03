import SwiftUI

/// The Search window: query row, result tabs and the "Search plugins…" button.
struct SearchWindow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openWindow) private var openWindow
    @State private var model = SearchModel()
    /// Snapshots: run this search on open.
    var initialPattern: String?

    var body: some View {
        @Bindable var model = model
        VStack(spacing: 0) {
            SearchQueryBar(model: model)
            Divider()
            content
            Divider()
            HStack {
                Text(model.currentTab?.status.text ?? "")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Search plugins…") { openWindow(id: FeatureWindowID.searchPlugins.rawValue) }
            }
            .padding(Design.Spacing.medium)
            .background(.bar)
        }
        .frame(minWidth: FeatureDesign.Window.searchMin.width, minHeight: FeatureDesign.Window.searchMin.height)
        .navigationTitle(AppWindowID.search.title)
        .alert(model.alert?.title ?? "", item: $model.alert) { _ in
            Button("OK") {}
        } message: { alert in
            Text(alert.message)
        }
        .task(id: app.phase) {
            await model.attach(app.client, profileRoot: app.launch.isSnapshot ? nil : app.launch.profileDirectory,
                               preferences: app.corePreferencesReader)
            if let initialPattern, model.tabs.isEmpty {
                model.pattern = initialPattern
                model.search()
            }
        }
        .task {
            for await event in app.events() {
                if case .searchPluginsUpdated = event { await model.reloadPlugins() }
            }
        }
        .onChange(of: app.corePreferences.behavior.storeSearchJobs) { model.storageSettingsChanged() }
        .onChange(of: app.corePreferences.behavior.storeSearchJobResults) { model.storageSettingsChanged() }
        .onAppear { if app.openWindow == nil { app.openWindow = openWindow } }
    }

    @ViewBuilder private var content: some View {
        if let status = model.engineStatus, !status.pythonFound {
            let usesCustomPath = !app.corePreferences.advanced.pythonExecutablePath.isEmpty
            ContentUnavailableView {
                Label(status.pythonVersion.isEmpty ? "Missing Python Runtime" : "Outdated Python Runtime",
                      systemImage: Symbol.exclamationmarkTriangle)
            } description: {
                Text(status.message)
                if usesCustomPath {
                    Text("Click Fix to clear the Python path and use the bundled Python.")
                } else {
                    Text("Set the Python path in Settings › Transfers › Search & RSS to Python 3.13 or later.")
                }
            } actions: {
                if usesCustomPath {
                    Button("Fix", action: useBundledPython)
                        .buttonStyle(.borderedProminent)
                }
                Button("Open Settings…") { app.revealSetting("python_executable_path") }
            }
        } else if model.engineStatus != nil, model.plugins.isEmpty {
            ContentUnavailableView {
                Label("No Search Plugins", systemImage: Symbol.puzzlepieceExtension)
            } description: {
                Text("There aren't any search plugins installed.\nClick the \"Search plugins...\" button at the bottom right of the window to install some.")
            }
        } else if model.tabs.isEmpty {
            ContentUnavailableView("Search", systemImage: Symbol.magnifyingglass,
                                   description: Text("Type a phrase and press Return to search with the enabled plugins."))
        } else {
            SearchTabStrip(model: model)
            if let tab = model.currentTab {
                SearchResultsView(model: model, tab: tab)
                    .id(tab.id)
            }
        }
    }

    /// "Fix": clears the custom Python path so the bundled Python is used,
    /// then checks again once the core has re-detected it.
    private func useBundledPython() {
        var prefs = app.corePreferences
        prefs.advanced.pythonExecutablePath = ""
        app.savePreferences(prefs)
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await model.reloadPlugins()
        }
    }}
