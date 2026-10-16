import SwiftUI

/// The properties tab strip. Clicking the selected tab collapses the panel,
/// clicking any tab while collapsed expands it. Resizing happens on
/// `PropertiesResizeHandle` above it, never on the tab buttons.
struct PropertiesTabBar: View {
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        HStack(spacing: Design.Spacing.tight) {
            ForEach(PropertiesTab.allCases) { tab in
                let selected = gui.propertiesVisible && gui.propertiesTab == tab
                Button {
                    select(tab)
                } label: {
                    Label(tab.title, systemImage: tab.systemImage)
                        .padding(.horizontal, Design.Spacing.regular)
                        .padding(.vertical, Design.Spacing.hairline)
                        .background(selected ? AnyShapeStyle(.selection.opacity(0.25)) : AnyShapeStyle(.clear),
                                    in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .keyboardShortcut(KeyEquivalent(tab.shortcutKey), modifiers: .option)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .help("\(tab.title) (⌥\(String(tab.shortcutKey).uppercased()))")
                if tab == .content { Spacer(minLength: Design.Spacing.medium) }
            }
            Button(gui.propertiesVisible ? "Hide Details" : "Show Details",
                   systemImage: gui.propertiesVisible ? Symbol.chevronDown : Symbol.chevronUp) {
                withAnimation(Design.Animation.quick) { gui.propertiesVisible.toggle() }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
        }
        .font(.callout)
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, Design.Spacing.medium)
        .frame(height: Design.Size.propertiesTabBarHeight)
        .background(.bar)
        .overlay(alignment: .bottom) { Divider().opacity(gui.propertiesVisible ? 1 : 0) }
    }

    private func select(_ tab: PropertiesTab) {
        withAnimation(Design.Animation.quick) {
            if gui.propertiesVisible, gui.propertiesTab == tab {
                gui.propertiesVisible = false
            } else {
                gui.propertiesTab = tab
                gui.propertiesVisible = true
            }
        }
    }
}
