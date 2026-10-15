import SwiftUI

/// Separate TRACKER STATUS section (`SeparateTrackerStatusFilter`).
struct TrackerStatusSidebarSection: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        let counts = model.list.counts
        Section(isExpanded: $gui.trackerStatusSectionExpanded) {
            ForEach(TrackerStatusFilter.allCases, id: \.self) { filter in
                SidebarRow(title: filter.title, systemImage: filter.systemImage, count: count(filter, counts))
                    .tag(SidebarItem.trackerStatus(filter))
                    .contextMenu { SidebarTorrentActions() }
            }
        } header: {
            Text("Tracker Status")
        }
        .onChange(of: gui.trackerStatusSectionExpanded) { _, expanded in
            if !expanded { model.list.trackerStatusFilter = .all }
        }
    }

    private func count(_ filter: TrackerStatusFilter, _ counts: SidebarCounts) -> Int {
        switch filter {
        case .all: counts.total
        case .warning: counts.warning
        case .trackerError: counts.trackerError
        case .otherError: counts.otherError
        }
    }
}
