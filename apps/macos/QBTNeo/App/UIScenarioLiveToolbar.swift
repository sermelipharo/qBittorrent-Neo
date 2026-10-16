#if DEBUG
import AppKit

/// Live-run scenario "live-toolbar" (use with `--demo`): the main window toolbar, rendered from the command
/// registry, driven like a user — Stop, Start and Remove (cancelled) on a selected torrent.
extension UIScenarios {
    static func liveToolbar(_ d: UIDriver) async throws {
        try await waitRunning(d)
        _ = try mainWindow(d)
        await d.pause(1)

        // Nothing selected: torrent commands do not apply.
        d.model.list.selection = []
        await d.pause(0.5)
        d.log("selection after clearing: \(d.model.list.selection.count) ids, selectedIDs \(d.model.list.selectedIDs.count)")
        let none = CommandContext(selectionOf: d.model)
        for id in [CommandID.start, .stop, .remove] {
            d.check(!CommandRegistry[id].canRun(in: none), "\(id) is disabled without a selection")
        }
        await d.shot("toolbar-no-selection")

        // Select a running torrent: Stop applies, Start does not.
        guard let item = d.model.list.visibleItems.first(where: { !$0.state.isStopped }) else {
            throw UIDriver.Failure(description: "no running torrent (use --demo)")
        }
        _ = try await selectTorrent(d, named: item.name)
        let ids = d.model.list.selectedIDs
        let running = CommandContext(selectionOf: d.model)
        d.check(CommandRegistry[.stop].canRun(in: running), "Stop applies to the running torrent")
        d.check(!CommandRegistry[.start].canRun(in: running), "Start does not apply to the running torrent")
        await d.shot("toolbar-selected")

        try await clickToolbar(d, label: "Stop", tooltipPrefix: "Stop (") { d.model.stop(ids) }
        let stopped = await d.wait(timeout: 15) { d.model.items(ids).allSatisfy { $0.state.isStopped } }
        d.check(stopped, "toolbar Stop stopped the torrent (state \(d.model.items(ids).map { "\($0.state)" }))")
        await d.pause(1)
        let paused = CommandContext(selectionOf: d.model)
        d.check(CommandRegistry[.start].canRun(in: paused) && !CommandRegistry[.stop].canRun(in: paused),
                "after Stop, Start applies and Stop does not")
        await d.shot("toolbar-stopped")

        try await clickToolbar(d, label: "Start", tooltipPrefix: "Start (") { d.model.start(ids) }
        let started = await d.wait(timeout: 15) { d.model.items(ids).allSatisfy { !$0.state.isStopped } }
        d.check(started, "toolbar Start started the torrent")

        // Another torrent: the buttons act on the new selection, not on the one they were first drawn with.
        try await stopStartSecond(d, first: ids)
        // Several torrents at once.
        try await stopStartMultiple(d)

        // Remove opens the confirmation; cancelling keeps the torrent.
        let count = d.model.transfers.items.count
        try await clickToolbar(d, label: "Remove", tooltipPrefix: "Remove (") { d.model.requestRemove(ids) }
        let sheet = await d.wait(timeout: 5) { d.model.sheet != nil || sheetWindow(d) != nil }
        d.check(sheet, "toolbar Remove asked for confirmation")
        await d.shot("toolbar-remove-confirm")
        await d.pressEscape(window: sheetWindow(d))
        _ = await d.wait(timeout: 3) { sheetWindow(d) == nil }
        let afterCancel = d.model.transfers.items.count
        d.check(d.model.sheet == nil && afterCancel == count, "cancelled Remove kept every torrent (\(count) before, \(afterCancel) after)")
        await d.pause(1)

        // Alternative speed limits share one on/off state across the registry command and the model.
        let command = CommandRegistry[.alternativeSpeedLimits]
        let before = d.model.alternativeSpeedLimits
        d.check(command.isOn?(d.model) == before, "registry state matches the model (\(before))")
        command.perform(CommandContext(selectionOf: d.model))
        let flipped = await d.wait(timeout: 4) { d.model.alternativeSpeedLimits != before }
        d.check(flipped && command.isOn?(d.model) == !before, "registry command toggled alternative speed limits")
        d.model.setAltSpeedLimits(before)
        d.log("toolbar scenario done; torrents now \(d.model.transfers.items.count)")
    }

    private static func stopStartSecond(_ d: UIDriver, first: [String]) async throws {
        guard let other = d.model.list.visibleItems.first(where: { !$0.state.isStopped && !first.contains($0.id) }) else {
            throw UIDriver.Failure(description: "no second running torrent")
        }
        _ = try await selectTorrent(d, named: other.name)
        await d.pause(0.5)
        try await clickToolbar(d, label: "Stop", tooltipPrefix: "Stop (") { d.model.stop([other.id]) }
        let stopped = await d.wait(timeout: 10) { d.model.items([other.id]).allSatisfy { $0.state.isStopped } }
        d.check(stopped, "toolbar Stop stopped the newly selected \(other.name) (state \(d.model.items([other.id]).map { "\($0.state)" }))")
        d.check(d.model.items(first).allSatisfy { !$0.state.isStopped }, "the previously selected torrent kept running")
        try await clickToolbar(d, label: "Start", tooltipPrefix: "Start (") { d.model.start([other.id]) }
        let started = await d.wait(timeout: 10) { d.model.items([other.id]).allSatisfy { !$0.state.isStopped } }
        d.check(started, "toolbar Start started \(other.name)")
    }

    private static func stopStartMultiple(_ d: UIDriver) async throws {
        let table = try transferTable(d)
        let rows = d.model.list.visibleItems.enumerated().filter { !$0.element.state.isStopped }.prefix(3).map(\.offset)
        guard rows.count == 3 else { throw UIDriver.Failure(description: "fewer than 3 running torrents") }
        let ids = rows.map { d.model.list.visibleItems[$0].id }
        await d.clickRow(table, row: rows[0])
        // Extend the selection like Command-clicks (synthesized modifier clicks are not reliable in an inactive app).
        table.selectRowIndexes(IndexSet(rows), byExtendingSelection: false)
        await d.pause(0.6)
        d.check(Set(d.model.list.selectedIDs) == Set(ids), "three torrents selected (\(d.model.list.selectedIDs.count))")
        try await clickToolbar(d, label: "Stop", tooltipPrefix: "Stop (") { d.model.stop(ids) }
        let stopped = await d.wait(timeout: 10) { d.model.items(ids).allSatisfy { $0.state.isStopped } }
        d.check(stopped, "toolbar Stop stopped all three selected torrents")
        await d.shot("toolbar-multi-stopped")
        try await clickToolbar(d, label: "Start", tooltipPrefix: "Start (") { d.model.start(ids) }
        let started = await d.wait(timeout: 10) { d.model.items(ids).allSatisfy { !$0.state.isStopped } }
        d.check(started, "toolbar Start started all three selected torrents")
    }
}
#endif
