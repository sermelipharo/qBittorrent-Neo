import SwiftUI

/// Privacy pane header: "Encryption: allowed · VPN binding: off · Proxy: none
/// · IP filter: off"; each item scrolls to its section.
struct PrivacySummary: View {
    let prefs: Preferences
    @Environment(SettingsNavigator.self) private var navigator

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            item(String(localized: "Encryption: \(encryption)"), section: .encryption)
            separator
            item(String(localized: "VPN binding: \(prefs.advanced.currentNetworkInterface.isEmpty ? off : on)"), section: .vpn)
            separator
            item(String(localized: "Proxy: \(PreferenceChoices.title(prefs.connection.proxyType))"), section: .proxy)
            separator
            item(String(localized: "IP filter: \(prefs.connection.ipFilterEnabled ? on : off)"), section: .ipFilter)
        }
        .font(.callout)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Design.Spacing.regular)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: Design.Radius.medium))
        .padding(.top, SettingsLayout.sectionSpacing)
    }

    private var on: String { String(localized: "on") }
    private var off: String { String(localized: "off") }

    private var encryption: String {
        switch prefs.bittorrent.encryption {
        case .allow: String(localized: "allowed")
        case .require: String(localized: "required")
        case .disable: String(localized: "disabled")
        }
    }

    private var separator: some View {
        Text(verbatim: "·")
            .foregroundStyle(.tertiary)
    }

    private func item(_ text: String, section: SettingsSection) -> some View {
        Button(text) { navigator.scroll(to: section) }
            .buttonStyle(.link)
            .foregroundStyle(.secondary)
    }
}
