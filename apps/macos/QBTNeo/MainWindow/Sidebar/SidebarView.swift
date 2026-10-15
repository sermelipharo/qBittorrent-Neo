import SwiftUI

/// The filters sidebar. Each section keeps its own selected row; all
/// section filters combine (AND) with each other and the search field.
struct SidebarView: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui
    @Environment(\.isSnapshotRendering) private var isSnapshot

    var body: some View {
        @Bindable var list = model.list
        List(selection: $list.sidebarSelection) {
            StatusSidebarSection()
            CategorySidebarSection()
            TagSidebarSection()
            if gui.separateTrackerStatusFilter {
                TrackerStatusSidebarSection()
            }
            TrackerSidebarSection()
        }
        .listStyle(.sidebar)
        .scrollContentBackground(isSnapshot ? .hidden : .automatic)
        .background(isSnapshot ? AnyShapeStyle(.windowBackground) : AnyShapeStyle(.clear))
        .onChange(of: gui.statusSectionExpanded) { _, expanded in
            if !expanded { list.statusFilter = .all }
        }
    }
}
