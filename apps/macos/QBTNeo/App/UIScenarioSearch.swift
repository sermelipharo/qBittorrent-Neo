#if DEBUG
import AppKit

/// Scenario 4: a live search through the Search window, stored and restored across a relaunch.
extension UIScenarios {
    static var searchQuery: String { ProcessInfo.processInfo.environment["QBT_UI_QUERY"] ?? "ubuntu" }

    static func searchWindow(_ d: UIDriver) -> NSWindow? {
        d.windows.first { $0.title == "Search" || $0.title.hasPrefix("Search") && !$0.title.contains("plugin") }
    }

    static func openSearchWindow(_ d: UIDriver) async throws -> NSWindow {
        d.model.openWindow?(id: AppWindowID.search.rawValue)
        _ = await d.wait(timeout: 15) { searchWindow(d) != nil }
        guard let window = searchWindow(d) else { throw UIDriver.Failure(description: "Search window did not open") }
        d.log("Search window open: '\(window.title)'")
        return window
    }

    static func windowTexts(_ d: UIDriver, _ window: NSWindow) -> [String] {
        d.elements(in: window).filter { $0.role == "AXStaticText" && !$0.value.isEmpty }.map(\.value)
    }

    static func stopIfRunning(_ d: UIDriver, _ window: NSWindow) async {
        if let stop = d.find(role: "AXButton", label: "Stop", in: [window]).first {
            await d.click(stop)
            let stopped = await d.wait(timeout: 15) { d.find(role: "AXButton", label: "Stop", in: [window]).isEmpty }
            d.check(stopped, "running search stopped through the Stop button")
        } else {
            d.log("search had already finished (nothing to stop)")
        }
    }

    static func searchLive(_ d: UIDriver) async throws {
        try await waitRunning(d)
        let window = try await openSearchWindow(d)
        // The "Search" button is disabled until the plugins are loaded.
        _ = await d.wait(timeout: 30) { d.find(role: "AXButton", label: "Search", in: [window]).first?.enabled == true }
        let field = try await d.require(role: "AXTextField", in: [window])
        await d.click(field)
        await d.type(searchQuery, window: window)
        await d.shot("search-typed")
        let button = try await d.require(role: "AXButton", label: "Search", in: [window])
        d.check(button.enabled, "Search button enabled with plugin installed")
        await d.click(button)
        let started = await d.wait(timeout: 15) { d.find(role: "AXButton", label: "Stop", in: [window]).first != nil }
        d.check(started, "search started (Stop button shown)")
        // Wait for results to arrive.
        _ = await d.wait(timeout: 60) { windowTexts(d, window).contains("Search has finished") }
        d.log("window texts after the search: \(windowTexts(d, window).prefix(40))")
        await d.shot("search-results")
        await stopIfRunning(d, window)

        // Second search, stopped as soon as it runs (the plugin answers within a second or two).
        await d.click(field)
        for _ in 0 ..< searchQuery.count { await d.key("\u{7f}", code: 51, window: window) }
        await d.type("debian", window: window)
        let again = try await d.require(role: "AXButton", label: "Search", in: [window])
        await d.click(again)
        _ = await d.wait(timeout: 15) { d.find(role: "AXButton", label: "Stop", in: [window]).first != nil }
        await stopIfRunning(d, window)
        await d.pause(2)
        d.log("window texts after the second search: \(windowTexts(d, window).prefix(40))")
        await d.shot("search-stopped")
        let stored = (try? FileManager.default.contentsOfDirectory(atPath: d.model.launch.profileDirectory + "/qBittorrent/data/SearchUI")) ?? []
        d.log("stored search files: \(stored)")
        d.check(stored.contains("Session.json") && stored.contains { $0 != "Session.json" && $0.hasSuffix(".json") }, "session and results files stored")
        await quitThroughUI(d)
    }

    static func searchRestore(_ d: UIDriver) async throws {
        try await waitRunning(d)
        let window = try await openSearchWindow(d)
        await d.pause(5)
        let field = try await d.require(role: "AXTextField", in: [window])
        d.log("query field value after relaunch: '\(field.value)'")
        let texts = windowTexts(d, window)
        d.log("window texts after relaunch: \(texts.prefix(40))")
        let chips = d.find(labelContains: searchQuery, in: [window]).filter { $0.role != "AXTextField" }
        d.log("tab chips matching '\(searchQuery)': \(chips.map(\.description))")
        d.check(!chips.isEmpty, "restored tab chip for '\(searchQuery)' is shown in the tab strip")
        d.check(!d.find(labelContains: "debian", in: [window]).isEmpty, "restored tab chip for 'debian' is shown")
        d.check(field.value == "debian", "query field shows the current tab's query")
        d.check(d.find(role: "AXButton", label: "Stop", in: [window]).isEmpty, "restored tabs are not running")
        await d.shot("search-restored")
        if let chip = chips.first {
            await d.click(chip)
            await d.pause(2)
            let after = windowTexts(d, window)
            d.log("window texts after selecting the '\(searchQuery)' tab: \(after.prefix(40))")
            d.check(after.contains("Results (showing 100 out of 100):"), "stored results of the '\(searchQuery)' tab are restored (100)")
            await d.shot("search-restored-ubuntu")
        }
        await quitThroughUI(d)
    }
}
#endif
