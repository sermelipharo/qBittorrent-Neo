import SwiftUI

/// The divider between the transfer list and the properties panel: a thin
/// strip with its own layout space above the tab bar. Dragging it resizes the
/// panel; only this strip shows the resize pointer, so the tab buttons below
/// always take plain clicks.
struct PropertiesResizeHandle: View {
    @Environment(GUIPreferences.self) private var gui
    @Binding var dragHeight: Double?
    let baseHeight: Double
    /// Detail column height, bounding how tall the panel can be dragged.
    let maxHeight: Double

    var body: some View {
        Rectangle()
            .fill(.bar)
            .frame(height: Design.Size.propertiesResizeHandleHeight)
            .overlay(alignment: .top) { Divider() }
            .contentShape(.rect)
            .gesture(resizeGesture, isEnabled: gui.propertiesVisible)
            .pointerStyle(gui.propertiesVisible ? .rowResize : .default)
            .accessibilityElement()
            .accessibilityLabel(Text("Details divider"))
            .accessibilityIdentifier("properties-resize-handle")
            .accessibilityValue(Text(verbatim: "\(Int(baseHeight))"))
            .accessibilityAdjustableAction(adjust)
            .accessibilityHidden(!gui.propertiesVisible)
    }

    /// Ceiling of the panel height: the transfer list keeps its minimum height.
    private var ceiling: Double {
        let chrome = Design.Size.propertiesTabBarHeight + Design.Size.propertiesResizeHandleHeight
            + (gui.statusBarDisplayed ? Design.Size.statusBarHeight : 0)
        return max(maxHeight - Design.Size.transferListMinHeight - chrome, Design.Size.propertiesMinHeight)
    }

    private func clamped(_ height: Double) -> Double {
        min(max(height, Design.Size.propertiesMinHeight), ceiling)
    }

    /// VoiceOver (and keyboard access) resizes the panel in steps: increment makes it taller.
    private func adjust(_ direction: AccessibilityAdjustmentDirection) {
        let step = 24.0
        switch direction {
        case .increment: gui.propertiesHeight = clamped(baseHeight + step)
        case .decrement: gui.propertiesHeight = clamped(baseHeight - step)
        @unknown default: break
        }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                dragHeight = clamped(baseHeight - value.translation.height)
            }
            .onEnded { _ in
                if let dragHeight { gui.propertiesHeight = dragHeight }
                dragHeight = nil
            }
    }
}
