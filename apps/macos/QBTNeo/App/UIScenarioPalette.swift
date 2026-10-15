#if DEBUG
import AppKit

/// Scenario "palette": the Command Palette driven with real key events — ⌘K, typing, Tab into a torrent's
/// actions, Escape back, Return to jump, a filter, a toggle, a setting, ⌘1 — plus timings (use `--demo-large`).
extension UIScenarios {
    static func palettePanel() -> NSWindow? {
        NSApp.windows.first { $0 is CommandPalettePanel && $0.isVisible }
    }

    static func openPalette(_ d: UIDriver) async throws -> NSWindow {
        await d.command("k")
        _ = await d.wait(timeout: 5) { d.model.palette.isPresented && palettePanel() != nil }
        guard let panel = palettePanel() else { throw UIDriver.Failure(description: "palette did not open on Cmd-K") }
        // A scripted run keeps the app inactive, where AppKit has no key window; events go to the panel directly.
        d.log("palette panel key=\(panel.isKeyWindow) app active=\(NSApp.isActive)")
        d.check(panel.parent === d.model.mainWindow, "palette is a child of the main window (not floating)")
        d.check(panel.level == .normal, "palette uses the normal window level")
        return panel
    }

    static func down(_ d: UIDriver, _ panel: NSWindow) async {
        // NSDownArrowFunctionKey.
        await d.key("\u{F701}", code: 125, window: panel)
    }

    static func typeInPalette(_ d: UIDriver, _ text: String, _ panel: NSWindow) async {
        await d.type(text, window: panel)
        _ = await d.wait(timeout: 3) { d.model.palette.query == text }
        d.log("palette query '\(d.model.palette.query)': " + d.model.palette.sections.map { section in
            "[\(section.section.rawValue)] " + section.items.prefix(4).map(\.title).joined(separator: " | ")
        }.joined(separator: "  "))
    }

    static func palette(_ d: UIDriver) async throws {
        try await waitRunning(d)
        let palette = d.model.palette
        d.log("torrents: \(d.model.transfers.items.count)")

        // 1. Open: empty query lists recent items and every available action.
        var start = Date()
        var panel = try await openPalette(d)
        d.log(String(format: "open (index build) took %.1f ms", Date().timeIntervalSince(start) * 1000))
        d.check(palette.query.isEmpty && !palette.rows.isEmpty, "empty palette lists actions (\(palette.rows.count) rows)")
        d.check(palette.selectedID == palette.rows.first?.id, "first row selected")
        await down(d, panel)
        d.check(palette.selectedID == palette.rows.dropFirst().first?.id, "↓ selects the second row")

        // 2. A torrent: type, Tab into its actions, Escape back, Return jumps to it.
        guard let target = d.model.transfers.items.last else { throw UIDriver.Failure(description: "no torrents") }
        let words = target.name.split(separator: " ").prefix(2).joined(separator: " ")
        start = Date()
        await typeInPalette(d, words, panel)
        d.log(String(format: "typing %d characters took %.1f ms (incl. 0.2 s pause per key)", words.count,
                     Date().timeIntervalSince(start) * 1000))
        let torrentRow = "torrent:\(target.id)"
        if !palette.rows.contains(where: { $0.id == torrentRow }) { throw UIDriver.Failure(description: "torrent not found by '\(words)'") }
        while palette.selectedID != torrentRow { await down(d, panel) }
        await d.key("\t", code: 48, window: panel)
        d.check(palette.mode == .torrent(target.id), "Tab shows the torrent's actions (\(palette.rows.map(\.title).prefix(6)))")
        await d.pressEscape(window: panel)
        d.check(palette.mode == .root && palette.query == words, "Escape returns to the results with the query kept")
        d.check(palette.selectedID == torrentRow, "the torrent row is selected again")
        d.model.list.statusFilter = target.state.isStopped ? .running : .stopped
        await d.pause(0.5)
        await d.pressReturn(window: panel)
        _ = await d.wait(timeout: 3) { !palette.isPresented }
        await d.pause(0.5)
        d.check(!palette.isPresented && palettePanel() == nil, "Return closes the palette")
        d.check(d.model.list.selection == [target.id], "Return selects the torrent")
        d.check(d.model.list.statusFilter == .all, "filters hiding the torrent were reset")

        // 3. A filter.
        panel = try await openPalette(d)
        await typeInPalette(d, StatusFilter.downloading.title, panel)
        if let row = palette.rows.first(where: { $0.id == "filter:status:\(StatusFilter.downloading.index)" }) {
            palette.select(row.id)
            await d.pressReturn(window: panel)
            await d.pause(0.5)
            d.check(d.model.list.statusFilter == .downloading, "a status filter row applies the filter")
        } else {
            d.log("FAIL: no Downloading filter row")
        }

        // 4. A toggle through a keyword ("turtle" → Alternative Speed Limits).
        let before = d.model.alternativeSpeedLimits
        panel = try await openPalette(d)
        await typeInPalette(d, "turtle", panel)
        d.check(palette.selectedItem?.id == "command:alternativeSpeedLimits", "keyword finds Alternative Speed Limits first")
        await d.pressReturn(window: panel)
        _ = await d.wait(timeout: 3) { d.model.alternativeSpeedLimits != before }
        d.check(d.model.alternativeSpeedLimits != before, "Return toggled alternative speed limits")
        d.model.setAltSpeedLimits(before)

        // 5. ⌘1 runs the first row: "reset filters".
        panel = try await openPalette(d)
        await typeInPalette(d, "reset filters", panel)
        d.keyNow("1", code: 18, modifiers: .command, window: panel)
        await d.pause(0.6)
        d.check(!palette.isPresented && d.model.list.statusFilter == .all, "⌘1 ran Reset Filters")

        // 6. A setting opens Settings on its pane.
        panel = try await openPalette(d)
        await typeInPalette(d, "proxy", panel)
        if let row = palette.rows.first(where: { $0.id.hasPrefix("setting:") }) {
            palette.select(row.id)
            await d.pressReturn(window: panel)
            let shown = await d.wait(timeout: 8) {
                d.model.pendingSettingReveal == nil && d.windows.contains { $0 !== d.model.mainWindow && !($0 is CommandPalettePanel) }
            }
            d.check(shown, "a setting row opened Settings (windows: \(d.windows.map(\.title)))")
            for window in d.windows where window !== d.model.mainWindow { window.close() }
        } else {
            d.log("FAIL: no settings row for 'proxy'")
        }

        // 7. Escape closes, ⌘K toggles.
        panel = try await openPalette(d)
        await d.pressEscape(window: panel)
        d.check(!palette.isPresented, "Escape closes the palette")
        _ = try await openPalette(d)
        await d.command("k")
        d.check(!palette.isPresented, "⌘K again closes the palette")

        // 8. Per-keystroke cost over every torrent.
        palette.prepare(query: "")
        let queries = ["s", "si", "sin", "sint", "sinte", "sintel", "sintel 4"]
        start = Date()
        for query in queries { palette.query = query }
        d.log(String(format: "PERF: %.2f ms per keystroke over %d torrents", Date().timeIntervalSince(start) * 1000 / Double(queries.count),
                     d.model.transfers.items.count))
        palette.close()
        d.log("palette scenario done; exiting")
        exit(0)
    }
}
#endif
