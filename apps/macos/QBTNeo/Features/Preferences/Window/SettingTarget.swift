import Foundation

/// A setting to scroll to and highlight; `nonce` re-triggers the reveal when the same setting is picked twice.
struct SettingTarget: Equatable {
    let anchor: String
    let pane: SettingsPane
    var nonce = UUID()
}
