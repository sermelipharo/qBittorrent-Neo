import SwiftUI

/// Right-click menu of the status bar: which items to show.
struct StatusBarMenu: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        Toggle("Show Free Disk Space", isOn: $gui.statusBarFreeDiskSpace)
        Toggle("Show External IP", isOn: Bindable(model).showsExternalIP)
        Divider()
        Button("Hide Status Bar") { gui.statusBarDisplayed = false }
    }
}
