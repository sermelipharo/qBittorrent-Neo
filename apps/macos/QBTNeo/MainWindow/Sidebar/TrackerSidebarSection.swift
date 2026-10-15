import SwiftUI

/// TRACKERS section: All, Trackerless, the announce-status rows (unless the
/// separate section is enabled) and one row per host (features.md §1.5.4).
struct TrackerSidebarSection: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        let counts = model.list.counts
        Section(isExpanded: $gui.trackerSectionExpanded) {
            SidebarRow(title: String(localized: "All"), systemImage: "antenna.radiowaves.left.and.right", count: counts.total)
                .tag(SidebarItem.tracker(.all))
                .contextMenu { SidebarTorrentActions() }
            SidebarRow(title: String(localized: "Trackerless"), systemImage: "antenna.radiowaves.left.and.right.slash", count: counts.trackerless)
                .tag(SidebarItem.tracker(.trackerless))
                .contextMenu { SidebarTorrentActions() }
            if !gui.separateTrackerStatusFilter {
                SidebarRow(title: String(localized: "Tracker error"), systemImage: "xmark.octagon", count: counts.trackerError,
                           tint: TorrentState.error.color)
                    .tag(SidebarItem.tracker(.trackerError))
                    .contextMenu { SidebarTorrentActions() }
                SidebarRow(title: String(localized: "Other error"), systemImage: "xmark.octagon", count: counts.otherError,
                           tint: TorrentState.error.color)
                    .tag(SidebarItem.tracker(.otherError))
                    .contextMenu { SidebarTorrentActions() }
                SidebarRow(title: String(localized: "Warning"), systemImage: "exclamationmark.triangle", count: counts.warning, tint: .orange)
                    .tag(SidebarItem.tracker(.warning))
                    .contextMenu { SidebarTorrentActions() }
            }
            ForEach(model.trackers.sortedHosts, id: \.self) { host in
                SidebarRow(title: host, systemImage: "server.rack", count: counts.hosts[host] ?? 0,
                           image: gui.downloadTrackerFavicon ? model.favicons.icon(for: host) : nil)
                    .tag(SidebarItem.tracker(.host(host)))
                    .contextMenu {
                        Button("Remove Tracker", systemImage: "minus.circle") { model.requestRemoveTracker(host: host) }
                        Divider()
                        SidebarTorrentActions()
                    }
            }
        } header: {
            Text("Trackers")
        }
        .onChange(of: model.trackers.sortedHosts, initial: true) { model.requestTrackerFavicons() }
        .onChange(of: gui.downloadTrackerFavicon) { model.requestTrackerFavicons() }
        .onChange(of: gui.trackerSectionExpanded) { _, expanded in
            if !expanded { model.list.trackerFilter = .all }
        }
    }
}
