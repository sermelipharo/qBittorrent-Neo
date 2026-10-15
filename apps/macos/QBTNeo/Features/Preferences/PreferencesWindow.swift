import SwiftUI

/// The Settings window (docs/design/settings-ia.md §4): a non-customizable
/// toolbar of panes, the pane's centered column form, and a search field at
/// the trailing end of the toolbar (⌘F) whose results replace the pane while
/// it has text. The window takes each pane's height and the pane's name as
/// its title; changes apply immediately.
struct PreferencesWindow: View {
    @Environment(AppModel.self) private var app
    @State private var model = PreferencesModel()
    @State private var navigator: SettingsNavigator
    @State private var searchFocusRequest = 0

    init(navigator: SettingsNavigator? = nil) {
        _navigator = State(initialValue: navigator ?? SettingsNavigator())
    }

    var body: some View {
        @Bindable var navigator = navigator
        let isSearching = !navigator.query.trimmingCharacters(in: .whitespaces).isEmpty
        TabView(selection: $navigator.pane) {
            ForEach(SettingsPane.allCases) { pane in
                Group {
                    if isSearching {
                        SettingsSearchResults(query: navigator.query, open: open)
                    } else {
                        SettingsPaneContent(pane: pane, model: model)
                    }
                }
                .tabItem { Label(pane.title, systemImage: pane.symbol) }
                .tag(pane)
            }
        }
        .background {
            SettingsToolbarSearch(text: $navigator.query, focusRequest: searchFocusRequest) {
                if let first = SettingsSearch.search(navigator.query).first { open(first) }
            }
            .frame(width: 0, height: 0)
            Button("Search") { searchFocusRequest += 1 }
                .keyboardShortcut("f", modifiers: .command)
                .hidden()
        }
        .environment(navigator)
        .background {
            if app.launch.isSnapshot { SettingsWindowHider() }
        }
        .task(id: app.phase) {
            #if DEBUG
            SettingsCatalogCheck.verify()
            #endif
            await model.attach(app.client)
        }
        .onChange(of: app.corePreferences) { model.coreDidChange(app.corePreferences) }
    }

    private func open(_ result: SettingsSearch.Result) {
        navigator.query = ""
        navigator.reveal(result.spec)
    }
}
