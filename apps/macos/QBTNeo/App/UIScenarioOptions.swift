#if DEBUG
import AppKit

/// Scenario 1: Torrent Options discovery switches (DHT/PeX/LSD) through the real dialog.
extension UIScenarios {
    static let discoveryLabels = ["Disable DHT for this torrent", "Disable PeX for this torrent", "Disable LSD for this torrent"]

    /// Opens Torrent Options from the row's context menu and returns the sheet.
    static func openTorrentOptions(_ d: UIDriver, named name: String) async throws -> NSWindow {
        try await selectTorrent(d, named: name)
        let row = try rowIndex(d, named: name)
        let chosen = await d.contextMenuPerform(table: try transferTable(d), row: row, title: "Torrent Options…")
        d.check(chosen, "context menu item 'Torrent Options…' chosen")
        _ = await d.wait(timeout: 10) { sheetWindow(d) != nil }
        guard let sheet = sheetWindow(d) else { throw UIDriver.Failure(description: "Torrent Options sheet did not open") }
        // Wait for the form (and the discovery switches, which load asynchronously) to appear.
        _ = await d.wait(timeout: 15) {
            scrollToBottom(d, sheet)
            return discoverySwitch(d, sheet, label: discoveryLabels[0]) != nil
        }
        await d.pause(0.5)
        return sheet
    }

    /// The switch on the row whose label is `label` (matched by the row's vertical position).
    static func discoverySwitch(_ d: UIDriver, _ sheet: NSWindow, label: String) -> UIDriver.Element? {
        let all = d.elements(in: sheet)
        guard let text = all.first(where: { $0.role == "AXStaticText" && $0.value == label }) else { return nil }
        return all.first { $0.role == "AXCheckBox" && abs($0.frame.midY - text.frame.midY) < 12 }
    }

    static func switchStates(_ d: UIDriver, _ sheet: NSWindow) -> [String] {
        discoveryLabels.map { label in
            guard let toggle = discoverySwitch(d, sheet, label: label) else { return "missing" }
            return "\(toggle.value)/\(toggle.enabled ? "enabled" : "disabled")"
        }
    }

    static func closeSheet(_ d: UIDriver, _ sheet: NSWindow, button: String) async throws {
        let target = try await d.require(role: "AXButton", label: button, in: [sheet])
        await d.click(target)
        let closed = await d.wait(timeout: 8) { sheetWindow(d) == nil }
        d.check(closed, "sheet closed after \(button)")
    }

    static func showTrackersTab(_ d: UIDriver) async throws {
        // Clicking the selected tab collapses the panel, so only click when it is not already showing.
        if !(d.model.gui.propertiesVisible && d.model.gui.propertiesTab == .trackers) {
            let button = try await d.require(role: "AXButton", label: "Trackers", in: [try mainWindow(d)])
            await d.click(button)
        }
        let shown = await d.wait(timeout: 5) { d.model.gui.propertiesVisible && d.model.gui.propertiesTab == .trackers }
        d.check(shown, "Trackers tab is showing")
        await d.pause(2.5)
    }

    /// Rows of the Trackers tab (cell texts joined), read from the table's cells.
    static func trackerRows(_ d: UIDriver) throws -> [String] {
        let tables = d.views(in: try mainWindow(d), classNameContains: "TableView").compactMap { $0 as? NSTableView }
        guard let table = tables.first(where: { $0.tableColumns.contains { $0.title.hasPrefix("URL") } }) else { return [] }
        return d.tableTexts(table).map { $0.filter { !$0.isEmpty }.joined(separator: " | ") }
    }

    /// Whether the DHT, PeX and LSD sticky rows all show "Disabled".
    static func stickyRowsDisabled(_ rows: [String]) -> Bool {
        ["DHT", "PeX", "LSD"].allSatisfy { name in rows.contains { $0.contains(name) && $0.contains("Disabled") } }
    }

    static func optionsSet(_ d: UIDriver) async throws {
        try await waitRunning(d)
        try await addTorrentsThroughDialogs(d, paths: torrentPaths)
        d.check(d.model.transfers.items.count == 2, "both torrents added through the Add Torrent dialog")
        await d.pause(2)

        var sheet = try await openTorrentOptions(d, named: "uiverify-public.bin")
        await d.shot("options-public-before")
        d.log("public switches before: \(switchStates(d, sheet))")
        for label in discoveryLabels {
            guard let toggle = discoverySwitch(d, sheet, label: label) else {
                d.check(false, "switch '\(label)' found")
                continue
            }
            await d.click(toggle)
        }
        let clicked = switchStates(d, sheet)
        d.check(clicked.allSatisfy { $0.hasPrefix("1/") }, "three switches on after clicking them: \(clicked)")
        await d.shot("options-public-clicked")
        try await closeSheet(d, sheet, button: "OK")
        await d.pause(1.5)

        sheet = try await openTorrentOptions(d, named: "uiverify-public.bin")
        let reopened = switchStates(d, sheet)
        d.check(reopened.allSatisfy { $0.hasPrefix("1/enabled") }, "reopened dialog shows the switches on: \(reopened)")
        await d.shot("options-public-reopened")
        try await closeSheet(d, sheet, button: "Cancel")

        try await selectTorrent(d, named: "uiverify-public.bin")
        try await showTrackersTab(d)
        let rows = try trackerRows(d)
        d.log("trackers tab rows: \(rows)")
        d.check(stickyRowsDisabled(rows), "Trackers tab shows DHT/PeX/LSD as Disabled")
        await d.shot("options-trackers-disabled")

        sheet = try await openTorrentOptions(d, named: "uiverify-private.bin")
        let privateStates = switchStates(d, sheet)
        d.check(privateStates.allSatisfy { $0 == "1/disabled" }, "private torrent: switches checked and disabled: \(privateStates)")
        await d.shot("options-private")
        try await closeSheet(d, sheet, button: "Cancel")

        await quitThroughUI(d)
    }

    static func optionsVerify(_ d: UIDriver) async throws {
        try await waitRunning(d)
        _ = await d.wait(timeout: 20) { d.model.transfers.items.count == 2 }
        d.check(d.model.transfers.items.count == 2, "both torrents restored after relaunch")
        await d.pause(2)
        let sheet = try await openTorrentOptions(d, named: "uiverify-public.bin")
        let states = switchStates(d, sheet)
        d.check(states.allSatisfy { $0.hasPrefix("1/enabled") }, "after relaunch the switches are still on: \(states)")
        await d.shot("options-relaunch-dialog")
        try await closeSheet(d, sheet, button: "Cancel")
        try await selectTorrent(d, named: "uiverify-public.bin")
        try await showTrackersTab(d)
        let rows = try trackerRows(d)
        d.log("trackers tab rows: \(rows)")
        d.check(stickyRowsDisabled(rows), "after relaunch Trackers tab shows DHT/PeX/LSD as Disabled")
        await d.shot("options-relaunch-trackers")
        await quitThroughUI(d)
    }
}
#endif
