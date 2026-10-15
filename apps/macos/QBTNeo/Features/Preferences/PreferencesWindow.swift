import SwiftUI

/// The Settings window (features.md / preferences.md): a sidebar of pages with
/// search, each page a grouped form. Changes apply automatically.
struct PreferencesWindow: View {
    @Environment(AppModel.self) private var app
    @State private var model = PreferencesModel()
    @AppStorage("OptionsDialog/LastViewedPage") private var page = PreferencesPage.behavior
    @State private var query: String
    @State private var target: SettingTarget?
    /// Fixed page for snapshots.
    var pinnedPage: PreferencesPage?

    init(pinnedPage: PreferencesPage? = nil, initialQuery: String = "") {
        self.pinnedPage = pinnedPage
        _query = State(initialValue: initialQuery)
    }

    var body: some View {
        // The page list is the window's navigation, so it can't be hidden.
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 215, max: 260)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            PreferencesPageView(page: pinnedPage ?? page, model: model, target: target)
                .navigationTitle((pinnedPage ?? page).title)
        }
        .frame(minWidth: FeatureDesign.Window.preferencesMin.width, minHeight: FeatureDesign.Window.preferencesMin.height)
        .task(id: app.phase) { await model.attach(app.client) }
        .onChange(of: app.corePreferences) { model.coreDidChange(app.corePreferences) }
    }

    @ViewBuilder private var sidebar: some View {
        let results = PreferencesIndex.search(query)
        let isSearching = !query.trimmingCharacters(in: .whitespaces).isEmpty
        List(selection: $page) {
            if isSearching {
                ForEach(results) { result in
                    PreferencesSearchRow(result: result)
                        .tag(result.page)
                        .simultaneousGesture(TapGesture().onEnded { reveal(result) })
                }
            } else {
                ForEach(PreferencesPage.allCases) { page in
                    PreferencesPageLabel(page: page)
                }
            }
        }
        .overlay {
            if isSearching, results.isEmpty { ContentUnavailableView.search(text: query) }
        }
        .searchable(text: $query, placement: .sidebar, prompt: Text("Search"))
        .onChange(of: query) { _, _ in
            // Typing re-targets the best hit; the page opens when a result is clicked.
            target = nil
        }
        .onChange(of: page) { _, newPage in
            if isSearching, let result = results.first(where: { $0.page == newPage }) { reveal(result) }
        }
        .task {
            // Snapshot/launch with a query: open the first hit right away.
            if isSearching, let first = results.first { page = first.page; reveal(first) }
        }
    }

    private func reveal(_ result: PreferencesIndex.Result) {
        guard let anchor = result.anchor else {
            target = nil
            return
        }
        target = SettingTarget(page: result.page, anchor: anchor)
    }
}
