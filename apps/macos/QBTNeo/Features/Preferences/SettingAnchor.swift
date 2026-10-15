import SwiftUI

extension EnvironmentValues {
    /// Anchor of the setting briefly highlighted after opening it from the Settings search.
    @Entry var highlightedSetting: String?
}

private struct SettingAnchor: ViewModifier {
    let anchor: String
    @Environment(\.highlightedSetting) private var highlighted

    func body(content: Content) -> some View {
        content
            .id(anchor)
            .background(highlighted == anchor ? Color.accentColor.opacity(0.22) : Color.clear, in: .rect(cornerRadius: 6))
    }
}

extension View {
    /// Marks a setting (or a whole section) as a scroll/highlight target of the Settings search.
    func settingAnchor(_ anchor: String) -> some View {
        modifier(SettingAnchor(anchor: anchor))
    }
}

/// A search hit to reveal; `nonce` re-triggers the reveal when the same setting is picked twice.
struct SettingTarget: Equatable {
    let page: PreferencesPage
    let anchor: String
    var nonce = UUID()
}
