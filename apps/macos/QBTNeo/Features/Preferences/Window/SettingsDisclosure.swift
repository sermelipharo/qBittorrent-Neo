import SwiftUI

/// A collapsed group of rare settings inside a section ("More confirmations",
/// "Bind to address", "Tunnel settings"); search opens it.
struct SettingsDisclosure<Content: View>: View {
    let title: LocalizedStringKey
    let section: SettingsSection
    @ViewBuilder let content: Content
    @Environment(SettingsNavigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        DisclosureGroup(title, isExpanded: Binding(
            get: { navigator.expandedDisclosures.contains(section) },
            set: { isOn in
                if isOn { navigator.expandedDisclosures.insert(section) } else { navigator.expandedDisclosures.remove(section) }
            }
        )) {
            content
        }
    }
}
