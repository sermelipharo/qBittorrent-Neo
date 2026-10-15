import SwiftUI

/// STATUS section (features.md §1.5.1).
struct StatusSidebarSection: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        let counts = model.list.counts
        Section(isExpanded: $gui.statusSectionExpanded) {
            ForEach(visibleFilters(counts)) { filter in
                SidebarRow(title: filter.title, systemImage: filter.systemImage, count: counts.count(for: filter), tint: filter.tint)
                    .tag(SidebarItem.status(filter))
                    .contextMenu { SidebarTorrentActions() }
            }
        } header: {
            Text("Status")
        }
    }

    private func visibleFilters(_ counts: SidebarCounts) -> [StatusFilter] {
        guard gui.hideZeroStatusFilters else { return StatusFilter.ordered }
        return StatusFilter.ordered.filter { $0 == .all || counts.count(for: $0) > 0 || $0 == model.list.statusFilter }
    }
}
