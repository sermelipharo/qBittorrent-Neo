import AppKit
import SwiftUI

/// Snapshot mode for the real Settings window: the `Settings` scene renders
/// its pane toolbar and search field only inside that scene, so snapshots
/// open it (made fully transparent before it is first drawn), switch panes
/// through a non-persistent navigator and capture each state.
@MainActor
enum SettingsSnapshot {
    /// Navigator of the Settings scene in snapshot mode (writes nothing to the user's defaults).
    static let navigator = SettingsNavigator(
        defaults: UserDefaults(suiteName: "mk.lex.qbtneo.snapshots.settings") ?? .standard, persistent: false, pane: .general
    )
    /// The model of the app's scenes (the Settings scene's environment).
    static var appModel: AppModel?
    /// The Settings window, once it exists.
    static var window: NSWindow?
}
