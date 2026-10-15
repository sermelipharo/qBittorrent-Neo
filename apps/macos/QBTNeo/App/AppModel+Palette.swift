import AppKit

/// Navigation used by the Command Palette and the command registry: windows,
/// Settings, jumping to a torrent and applying a sidebar filter.
extension AppModel {
    func show(_ window: AppWindowID) {
        openWindow?(id: window.rawValue)
    }

    func showSettings() {
        openSettings?()
    }

    /// Opens Settings on the setting's pane, revealing and highlighting it.
    func revealSetting(_ id: String) {
        pendingSettingReveal = id
        showSettings()
    }

    /// Selects the torrent and scrolls it into view, resetting the filters first if they hide it.
    func revealTorrent(_ id: String) {
        guard transfers.item(id) != nil else { return }
        if !list.visibleItems.contains(where: { $0.id == id }) { list.resetAllFilters() }
        list.selection = [id]
        Task { @MainActor [weak self] in
            // Let the table apply the new rows and selection first.
            try? await Task.sleep(for: .milliseconds(60))
            self?.scrollTransferList(to: id)
        }
    }

    /// Applies a sidebar filter, showing the sidebar and expanding the filter's section.
    func applyFilter(_ filter: SidebarItem) {
        if !gui.filtersSidebarVisible { gui.filtersSidebarVisible = true }
        switch filter.section {
        case .status: gui.statusSectionExpanded = true
        case .category: gui.categorySectionExpanded = true
        case .tag: gui.tagSectionExpanded = true
        case .trackerStatus: gui.trackerStatusSectionExpanded = true
        case .tracker: gui.trackerSectionExpanded = true
        }
        list.select(filter)
    }

    /// SwiftUI's `Table` has no scroll-to-row; the transfer table is the one whose selection is this row.
    private func scrollTransferList(to id: String) {
        guard let row = list.visibleItems.firstIndex(where: { $0.id == id }), let root = mainWindow?.contentView else { return }
        var pending: [NSView] = [root]
        while let view = pending.popLast() {
            if let table = view as? NSTableView, table.numberOfRows == list.visibleItems.count, table.selectedRowIndexes.contains(row) {
                table.scrollRowToVisible(row)
                return
            }
            pending.append(contentsOf: view.subviews)
        }
    }
}
