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
}
#endif
