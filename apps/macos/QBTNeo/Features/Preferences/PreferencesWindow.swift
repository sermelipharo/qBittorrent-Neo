import SwiftUI

/// The Settings window (features.md / preferences.md): a sidebar of pages,
/// each a grouped form. Changes apply automatically.
struct PreferencesWindow: View {
    @Environment(AppModel.self) private var app
    @State private var model = PreferencesModel()
    @AppStorage("OptionsDialog/LastViewedPage") private var page = PreferencesPage.behavior
    /// Fixed page for snapshots.
    var pinnedPage: PreferencesPage?

    var body: some View {
        // The page list is the window's navigation, so it can't be hidden.
        NavigationSplitView(columnVisibility: .constant(.all)) {
            List(PreferencesPage.allCases, selection: $page) { page in
                PreferencesPageLabel(page: page)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: FeatureDesign.Width.sidebar, max: 260)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            PreferencesPageView(page: pinnedPage ?? page, model: model)
                .navigationTitle((pinnedPage ?? page).title)
        }
        .frame(minWidth: FeatureDesign.Window.preferencesMin.width, minHeight: FeatureDesign.Window.preferencesMin.height)
        .task(id: app.phase) { await model.attach(app.client) }
        .onChange(of: app.corePreferences) { model.coreDidChange(app.corePreferences) }
    }
}
