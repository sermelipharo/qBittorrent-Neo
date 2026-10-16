import SwiftUI

/// The main window: filters sidebar, transfer list with the properties panel,
/// status bar, toolbar and search field (features.md §1).
struct MainWindow: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var list = model.list
        @Bindable var gui = gui
        Group {
            if model.lock.isLocked {
                // Nothing of the session stays in the view tree while locked.
                UILockScreen()
            } else {
                NavigationSplitView(columnVisibility: $gui.sidebarVisibility) {
                    SidebarView()
                        .navigationSplitViewColumnWidth(
                            min: Design.Size.sidebarMinWidth, ideal: Design.Size.sidebarIdealWidth, max: Design.Size.sidebarMaxWidth
                        )
                } detail: {
                    TransferDetailView()
                }
                .toolbar { MainToolbar(model: model) }
                .searchable(text: $list.searchText, placement: .toolbar, prompt: Text("Filter torrents…"))
                .searchScopes($list.searchScope) {
                    ForEach(TransferSearchScope.allCases, id: \.self) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
            }
        }
        .modifier(MainWindowTitle())
        .modifier(MainPresentations())
        .overlay { StartupOverlay() }
        .background {
            WindowObserver(onVisibilityChange: { model.isMainWindowVisible = $0 || model.launch.assumesVisibleWindow }, onWindow: { model.mainWindow = $0 })
        }
        .onAppear {
            model.openWindow = openWindow
            model.openSettings = openSettings
        }
        .onOpenURL { model.open([$0]) }
        .onChange(of: gui.filtersSidebarVisible) { _, visible in
            if !visible { model.list.resetSidebarFilters() }
        }
        .frame(minWidth: Design.Window.mainMinSize.width, minHeight: Design.Window.mainMinSize.height)
    }
}
