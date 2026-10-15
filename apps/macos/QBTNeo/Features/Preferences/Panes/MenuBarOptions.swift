import SwiftUI

/// General › Dock & Menu Bar: what the menu bar item displays. The mode is a
/// basic choice; direction, count style and the other details are advanced.
struct MenuBarOptions: View {
    @Bindable var gui: GUIPreferences

    var body: some View {
        let enabled = gui.showMenuBarIcon
        let mode = gui.menuBarContentMode
        Picker(SettingsCatalog.title("Preferences/Desktop/MenuBarContentMode"), selection: $gui.menuBarContentMode) {
            ForEach(MenuBarContentMode.allCases) { Text($0.title).tag($0) }
        }
        .fixedSize()
        .disabled(!enabled)
        .setting("Preferences/Desktop/MenuBarContentMode", indented: true)

        Picker(SettingsCatalog.title("Preferences/Desktop/MenuBarSpeedDirection"), selection: $gui.menuBarSpeedDirection) {
            ForEach(MenuBarSpeedDirection.allCases) { Text($0.title).tag($0) }
        }
        .fixedSize()
        .disabled(!enabled || !mode.showsSpeed)
        .setting("Preferences/Desktop/MenuBarSpeedDirection", indented: true)

        Toggle(SettingsCatalog.title("Preferences/Desktop/MenuBarHidesZeroSpeed"), isOn: $gui.menuBarHidesZeroSpeed)
            .disabled(!enabled || !mode.showsSpeed)
            .setting("Preferences/Desktop/MenuBarHidesZeroSpeed", indented: true)

        Picker(SettingsCatalog.title("Preferences/Desktop/MenuBarCountStyle"), selection: $gui.menuBarCountStyle) {
            ForEach(MenuBarCountStyle.allCases) { Text($0.title).tag($0) }
        }
        .fixedSize()
        .disabled(!enabled || !mode.showsCount)
        .setting("Preferences/Desktop/MenuBarCountStyle", indented: true)

        Toggle(SettingsCatalog.title("Preferences/Desktop/MenuBarShowsIcon"), isOn: $gui.menuBarShowsIcon)
            .disabled(!enabled || mode == .iconOnly)
            .setting("Preferences/Desktop/MenuBarShowsIcon", indented: true)
    }
}
