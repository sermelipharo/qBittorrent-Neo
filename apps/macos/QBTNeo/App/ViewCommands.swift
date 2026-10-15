import SwiftUI

/// View menu: Command Palette, status bar, speed in title, feature windows,
/// log filter, statistics. Buttons come from the command registry.
struct ViewCommands: View {
    let model: AppModel
    @Bindable var gui: GUIPreferences

    var body: some View {
        let context = CommandContext(selectionOf: model)
        Button(String(localized: "palette.menu", defaultValue: "Command Palette…", comment: "View menu item opening the Command Palette"),
               systemImage: Symbol.command) { model.palette.toggle() }
            .keyboardShortcut("k")
        Divider()
        Toggle("Status Bar", isOn: $gui.statusBarDisplayed)
        Toggle("Filters Sidebar", isOn: $gui.filtersSidebarVisible)
        Toggle("Speed in Title Bar", isOn: $gui.speedInTitleBar)
        Divider()
        CommandMenuItem(.searchEngine, context: context)
        CommandMenuItem(.rssReader, context: context)
        Menu("Log") {
            CommandMenuItem(.executionLog, context: context)
            Divider()
            Toggle("Normal Messages", isOn: $gui[logType: 0x1])
            Toggle("Information Messages", isOn: $gui[logType: 0x2])
            Toggle("Warning Messages", isOn: $gui[logType: 0x4])
            Toggle("Critical Messages", isOn: $gui[logType: 0x8])
        }
        Divider()
        LockCommands(model: model, context: context)
        Divider()
        CommandMenuItem(.statistics, context: context)
        Divider()
        CommandMenuItem(.globalSpeedLimits, context: context)
        Toggle("Alternative Speed Limits", isOn: Bindable(model).alternativeSpeedLimits)
            .keyboardShortcut(CommandRegistry[.alternativeSpeedLimits].shortcut?.keyboardShortcut)
    }
}
