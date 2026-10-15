import SwiftUI

extension EnvironmentValues {
    /// Anchor of the setting briefly highlighted after opening it from the Settings search.
    @Entry var highlightedSetting: String?
}

/// Wraps one Settings row: hides it by tier, marks it as a scroll/highlight
/// target, and shows its catalog explanation as a footnote under the control.
struct SettingRow: ViewModifier {
    let id: String
    var showsHelp = true
    var indented = false
    @Environment(SettingsNavigator.self) private var navigator
    @Environment(\.highlightedSetting) private var highlighted

    func body(content: Content) -> some View {
        let spec = SettingsCatalog.spec(id)
        if spec.map(navigator.shows) ?? true {
            content
                .padding(.leading, indented ? SettingsLayout.indent : 0)
                .id(id)
                .background {
                    RoundedRectangle(cornerRadius: SettingsLayout.highlightRadius)
                        .fill(Color.accentColor.opacity(highlighted == id ? 0.22 : 0))
                        .padding(-SettingsLayout.highlightInset)
                }
            if showsHelp, let help = spec?.help {
                SettingFootnote(text: help)
                    .padding(.leading, indented ? SettingsLayout.indent : 0)
            }
        }
    }
}

extension View {
    /// A Settings row backed by the catalog entry `id` (anchor, tier, footnote).
    func setting(_ id: String, help: Bool = true, indented: Bool = false) -> some View {
        modifier(SettingRow(id: id, showsHelp: help, indented: indented))
    }
}
