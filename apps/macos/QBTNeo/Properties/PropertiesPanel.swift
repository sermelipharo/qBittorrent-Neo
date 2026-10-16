import SwiftUI

/// Properties panel below the transfer list: resize handle, tab strip and the visible page.
/// Only the visible page is fetched, on selection/tab change and every tick.
struct PropertiesPanel: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui
    @State private var dragHeight: Double?
    /// Height of the detail column (list + panel + status bar).
    let availableHeight: Double

    /// Stored height, or the default share of the column when never resized;
    /// kept so the transfer list always retains its minimum height.
    private var baseHeight: Double {
        let chrome = Design.Size.propertiesTabBarHeight + Design.Size.propertiesResizeHandleHeight + (gui.statusBarDisplayed ? Design.Size.statusBarHeight : 0)
        let maxHeight = max(availableHeight - chrome - Design.Size.transferListMinHeight, Design.Size.propertiesMinHeight)
        let wanted = gui.propertiesHeight > 0 ? gui.propertiesHeight : availableHeight * Design.Size.propertiesDefaultFraction
        return min(max(wanted, Design.Size.propertiesMinHeight), maxHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            PropertiesResizeHandle(dragHeight: $dragHeight, baseHeight: baseHeight, maxHeight: availableHeight)
            PropertiesTabBar()
            if gui.propertiesVisible {
                PropertiesPage(tab: gui.propertiesTab)
                    .frame(height: dragHeight ?? baseHeight)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: RefreshKey(tab: gui.propertiesTab, visible: gui.propertiesVisible, current: model.list.currentID,
                             period: gui.speedGraphPeriod)) {
            await model.refreshProperties()
        }
    }

    private struct RefreshKey: Equatable {
        let tab: PropertiesTab
        let visible: Bool
        let current: String?
        let period: SpeedGraphPeriod
    }
}
