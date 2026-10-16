#if DEBUG
import AppKit

/// Live-run scenario "live-details" (use with `--demo`): the properties tab bar under the panel divider. Checks
/// that the divider's hit area never overlaps a tab button, that clicking every tab switches to it, that the
/// selected tab collapses and re-expands the panel, and that dragging the divider resizes the panel.
extension UIScenarios {
    static func liveDetails(_ d: UIDriver) async throws {
        try await waitRunning(d)
        let window = try mainWindow(d)
        d.model.gui.propertiesVisible = true
        d.model.gui.propertiesTab = .general
        if let item = d.model.list.visibleItems.first { _ = try await selectTorrent(d, named: item.name) }
        await d.pause(1)

        let handle = try await d.require(identifier: "properties-resize-handle", in: [window])
        let tabs = try PropertiesTab.allCases.map { tab in
            guard let button = tabButton(d, tab, in: window) else { throw UIDriver.Failure(description: "tab button \(tab.title) not found") }
            return (tab, button)
        }
        d.log("divider hit rect \(handle.frame)")
        for (tab, button) in tabs {
            let overlap = handle.frame.intersection(button.frame)
            d.check(overlap.isNull || overlap.isEmpty, "divider hit rect does not intersect the \(tab.title) tab \(button.frame)")
        }
        let tabsTop = tabs.map(\.1.frame.maxY).max() ?? 0
        d.check(handle.frame.minY >= tabsTop, "divider sits above the tab buttons (gap \(Int(handle.frame.minY - tabsTop)) pt)")
        await d.shot("details-tabs")

        // Every tab switches with a plain click (General is selected, so start with the next one).
        for tab in PropertiesTab.allCases.dropFirst() + [.general] {
            guard let button = tabButton(d, tab, in: window) else { throw UIDriver.Failure(description: "tab \(tab.title) vanished") }
            await d.click(button)
            let switched = await d.wait(timeout: 3) { d.model.gui.propertiesVisible && d.model.gui.propertiesTab == tab }
            d.check(switched, "click on \(tab.title) switched to it (now \(d.model.gui.propertiesTab.title), visible \(d.model.gui.propertiesVisible))")
        }

        // Clicking the selected tab collapses the panel; clicking it again expands it.
        if let general = tabButton(d, .general, in: window) {
            await d.click(general)
            let collapsed = await d.wait(timeout: 3) { !d.model.gui.propertiesVisible }
            d.check(collapsed, "click on the selected tab collapsed the panel")
            await d.shot("details-collapsed")
        }
        if let general = tabButton(d, .general, in: window) {
            await d.click(general)
            let expanded = await d.wait(timeout: 3) { d.model.gui.propertiesVisible && d.model.gui.propertiesTab == .general }
            d.check(expanded, "click on a tab of the collapsed panel expanded it")
        }
        await d.pause(0.8)

        // The divider resizes the panel: a synthesized drag (logged only: SwiftUI gestures ignore synthesized drags
        // of an inactive app), then its accessibility increment/decrement, which run the same height clamp.
        let handleNow = try await d.require(identifier: "properties-resize-handle", in: [window])
        let before = d.model.gui.propertiesHeight
        await d.drag(handleNow, by: NSPoint(x: 0, y: 60))
        d.log("after synthesized drag: height \(Int(before)) → \(Int(d.model.gui.propertiesHeight))")
        let tabsBefore = tabButton(d, .general, in: window)?.frame.minY ?? 0
        let heightBefore = d.model.gui.propertiesHeight
        d.log("divider element \(handleNow.object.className) actions \((handleNow.object.value(forKey: "accessibilityActionNames") as? [String]) ?? [])")
        let incremented = d.perform("accessibilityPerformIncrement", on: handleNow.object)
        _ = await d.wait(timeout: 3) { d.model.gui.propertiesHeight != heightBefore }
        await d.pause(0.5)
        let tabsAfter = tabButton(d, .general, in: window)?.frame.minY ?? 0
        let taller = incremented && d.model.gui.propertiesHeight > heightBefore && tabsAfter > tabsBefore
        let grown = "\(Int(heightBefore)) → \(Int(d.model.gui.propertiesHeight)), tabs moved up \(Int(tabsAfter - tabsBefore)) pt"
        d.check(taller, "divider increment made the panel taller (\(grown))")
        let heightTall = d.model.gui.propertiesHeight
        d.perform("accessibilityPerformDecrement", on: handleNow.object)
        let shrank = await d.wait(timeout: 3) { d.model.gui.propertiesHeight < heightTall }
        d.check(shrank, "divider decrement made the panel shorter (\(Int(heightTall)) → \(Int(d.model.gui.propertiesHeight)))")
        d.check(d.model.gui.propertiesTab == .general && d.model.gui.propertiesVisible, "resizing did not switch or collapse tabs")
        await d.shot("details-resized")
    }

    /// The tab button of the properties bar (the one level with the Hide/Show Details button).
    private static func tabButton(_ d: UIDriver, _ tab: PropertiesTab, in window: NSWindow) -> UIDriver.Element? {
        let toggle = d.find(role: "AXButton", label: "Hide Details", in: [window]).first
            ?? d.find(role: "AXButton", label: "Show Details", in: [window]).first
        let buttons = d.find(role: "AXButton", label: tab.title, in: [window])
        return toggle.flatMap { toggle in buttons.first { abs($0.frame.midY - toggle.frame.midY) < 12 } } ?? buttons.first
    }
}
#endif
