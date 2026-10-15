import SwiftUI

/// The Search window: query row, result tabs and the "Search plugins…" button.
struct SearchWindow: View {
    @Environment(AppModel.self) private var app
    @Environment(\.openWindow) private var openWindow
    @State private var model = SearchModel()
    @AppStorage(FeatureDefaults.storeSearchTabs) private var storesTabs = false
    @AppStorage(FeatureDefaults.storeSearchResults) private var storesResults = false
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
            await model.attach(app.client, profileRoot: app.launch.isSnapshot ? nil : app.launch.profileDirectory)
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
        .onChange(of: storesTabs) { model.storageSettingsChanged() }
        .onChange(of: storesResults) { model.storageSettingsChanged() }
        .onAppear { if app.openWindow == nil { app.openWindow = openWindow } }
    }

    @ViewBuilder private var content: some View {
        if let status = model.engineStatus, !status.pythonFound {
            ContentUnavailableView {
                Label("Missing Python Runtime", systemImage: "exclamationmark.triangle")
            } description: {
                Text("Python is required to use the search engine but it does not seem to be installed.")
                Text(status.message)
                Text("Install Python 3.9 or later (for example from python.org or with Homebrew), or set its path in Settings › Advanced.")
            }
        } else if model.engineStatus != nil, model.plugins.isEmpty {
            ContentUnavailableView {
                Label("No Search Plugins", systemImage: "puzzlepiece.extension")
            } description: {
                Text("There aren't any search plugins installed.\nClick the \"Search plugins...\" button at the bottom right of the window to install some.")
            }
        } else if model.tabs.isEmpty {
            ContentUnavailableView("Search", systemImage: "magnifyingglass",
                                   description: Text("Type a phrase and press Return to search with the enabled plugins."))
        } else {
            SearchTabStrip(model: model)
            if let tab = model.currentTab {
                SearchResultsView(model: model, tab: tab)
                    .id(tab.id)
            }
        }
    }
}
