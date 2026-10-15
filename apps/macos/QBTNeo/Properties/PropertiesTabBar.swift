import SwiftUI

/// The properties tab strip. Clicking the selected tab collapses the panel,
/// clicking any tab while collapsed expands it; dragging resizes the panel.
struct PropertiesTabBar: View {
    @Environment(GUIPreferences.self) private var gui
    @Binding var dragHeight: Double?
    let baseHeight: Double
    /// Detail column height, bounding how tall the panel can be dragged.
    let maxHeight: Double

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
                   systemImage: gui.propertiesVisible ? "chevron.down" : "chevron.up") {
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
        .overlay(alignment: .top) { Divider() }
        .overlay(alignment: .bottom) { Divider().opacity(gui.propertiesVisible ? 1 : 0) }
        .gesture(resizeGesture)
        .pointerStyle(gui.propertiesVisible ? .rowResize : .default)
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

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .global)
            .onChanged { value in
                guard gui.propertiesVisible else { return }
                let ceiling = maxHeight - Design.Size.transferListMinHeight - Design.Size.propertiesTabBarHeight
                    - (gui.statusBarDisplayed ? Design.Size.statusBarHeight : 0)
                dragHeight = min(max(baseHeight - value.translation.height, Design.Size.propertiesMinHeight), max(ceiling, Design.Size.propertiesMinHeight))
            }
            .onEnded { _ in
                if let dragHeight { gui.propertiesHeight = dragHeight }
                dragHeight = nil
            }
    }
}
