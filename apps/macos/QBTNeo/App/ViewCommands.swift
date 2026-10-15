import SwiftUI

/// View menu: status bar, speed in title, feature windows, log filter, statistics.
struct ViewCommands: View {
    let model: AppModel
    @Bindable var gui: GUIPreferences
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Status Bar", isOn: $gui.statusBarDisplayed)
        Toggle("Filters Sidebar", isOn: $gui.filtersSidebarVisible)
        Toggle("Speed in Title Bar", isOn: $gui.speedInTitleBar)
        Divider()
        Button("Search Engine", systemImage: "magnifyingglass") { openWindow(id: AppWindowID.search.rawValue) }
            .keyboardShortcut("2", modifiers: .option)
        Button("RSS Reader", systemImage: "dot.radiowaves.up.forward") { openWindow(id: AppWindowID.rss.rawValue) }
            .keyboardShortcut("3", modifiers: .option)
        Menu("Log") {
            Button("Show Execution Log") { openWindow(id: AppWindowID.log.rawValue) }
                .keyboardShortcut("4", modifiers: .option)
            Divider()
            Toggle("Normal Messages", isOn: $gui[logType: 0x1])
            Toggle("Information Messages", isOn: $gui[logType: 0x2])
            Toggle("Warning Messages", isOn: $gui[logType: 0x4])
            Toggle("Critical Messages", isOn: $gui[logType: 0x8])
        }
        Divider()
        LockCommands(model: model)
        Divider()
        Button("Statistics", systemImage: "chart.bar") { openWindow(id: AppWindowID.statistics.rawValue) }
            .keyboardShortcut("i")
        Divider()
        Button("Global Speed Limits…", systemImage: "speedometer") { model.sheet = .speedLimits }
        Toggle("Alternative Speed Limits", isOn: Bindable(model).alternativeSpeedLimits)
            .keyboardShortcut("t", modifiers: [.command, .shift])
    }
}
