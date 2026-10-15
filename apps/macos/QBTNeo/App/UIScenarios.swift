#if DEBUG
import AppKit

/// Scripted end-to-end scenarios run through `UIDriver` (DEBUG only): dispatcher and shared helpers.
@MainActor
enum UIScenarios {
    static func run(_ name: String, driver: UIDriver) async {
        driver.log("scenario \(name) starting")
        do {
            switch name {
            case "idle": try await waitRunning(driver)  // stays open (idle measurements)
            case "probe": try await probe(driver)
            case "options-set": try await optionsSet(driver)
            case "options-verify": try await optionsVerify(driver)
            case "lock-quit": try await lockQuit(driver)
            case "lock-ae": try await lockAppleEvent(driver)
            case "search-live": try await searchLive(driver)
            case "search-restore": try await searchRestore(driver)
            case "bunny": try await bunny(driver)
            case "ubuntu": try await ubuntu(driver)
            case "remove-probe": try await removeProbe(driver)
            case "palette": try await palette(driver)
            default: throw UIDriver.Failure(description: "unknown scenario \(name)")
            }
            driver.log("scenario \(name) finished")
        } catch {
            driver.log("FAIL: scenario \(name) aborted: \(error)")
            // Nothing else will quit a failed run; leave after the log is written.
            NSApp.terminate(nil)
        }
    }

    static var torrentPaths: [String] {
        (ProcessInfo.processInfo.environment["QBT_UI_TORRENT"] ?? "").split(separator: ":").map(String.init)
    }

    static func waitRunning(_ driver: UIDriver) async throws {
        let ok = await driver.wait(timeout: 60) { driver.model.phase == .running }
        if !ok { throw UIDriver.Failure(description: "core did not reach running phase") }
        _ = await driver.wait(timeout: 20) { driver.model.mainWindow?.isVisible == true }
        await driver.pause(1.5)
    }

    /// Adds torrent files by clicking "Add" in each Add Torrent dialog.
    static func addTorrentsThroughDialogs(_ d: UIDriver, paths: [String]) async throws {
        for path in paths {
            let name = URL(filePath: path).lastPathComponent
            d.model.open([URL(filePath: path)])
            _ = try await d.require(role: "AXButton", label: "Add", timeout: 15)
            let before = d.model.transfers.items.count
            for attempt in 1 ... 3 {
                guard let add = await d.settled(role: "AXButton", label: "Add") else { break }
                d.log("add dialog for \(name) in window '\(add.window.title)' enabled=\(add.enabled) (attempt \(attempt))")
                await d.click(add)
                if await d.wait(timeout: 4, { d.find(role: "AXButton", label: "Add").isEmpty }) { break }
            }
            _ = await d.wait(timeout: 10) { d.model.transfers.items.count > before }
        }
    }

    // MARK: Helpers

    static func mainWindow(_ d: UIDriver) throws -> NSWindow {
        guard let window = d.model.mainWindow else { throw UIDriver.Failure(description: "no main window") }
        return window
    }

    static func transferTable(_ d: UIDriver) throws -> NSTableView {
        let window = try mainWindow(d)
        let tables = d.views(in: window, classNameContains: "OutlineTableView").compactMap { $0 as? NSTableView }
        // The transfer table is the one with the "Name" and "Progress" columns (the Trackers table has neither).
        let titles: (NSTableView) -> [String] = { $0.tableColumns.map(\.title) }
        guard let table = tables.first(where: { titles($0).contains("Progress") && titles($0).contains("Name") }) else {
            for t in tables { d.log("table columns: \(titles(t))") }
            throw UIDriver.Failure(description: "transfer table not found")
        }
        return table
    }

    static func rowIndex(_ d: UIDriver, named name: String) throws -> Int {
        guard let index = d.model.list.visibleItems.firstIndex(where: { $0.name == name }) else {
            throw UIDriver.Failure(description: "torrent \(name) not in the list")
        }
        return index
    }

    /// Clicks the row of the torrent called `name` (by its visible position in the list).
    @discardableResult
    static func selectTorrent(_ d: UIDriver, named name: String) async throws -> TorrentItem {
        let index = try rowIndex(d, named: name)
        let item = d.model.list.visibleItems[index]
        await d.clickRow(try transferTable(d), row: index)
        d.check(d.model.list.selection == [item.id], "row for \(name) selected (\(item.id.prefix(8)))")
        return item
    }

    static func sheetWindow(_ d: UIDriver) -> NSWindow? {
        d.windows.first { $0.isSheet }
    }

    /// Scrolls the form of a sheet to its bottom so every control is hit-testable.
    static func scrollToBottom(_ d: UIDriver, _ window: NSWindow) {
        let scrolls = d.views(in: window, classNameContains: "ScrollView").compactMap { $0 as? NSScrollView }
        guard let scroll = scrolls.max(by: { $0.frame.height < $1.frame.height }), let document = scroll.documentView else { return }
        let top = max(0, document.frame.height - scroll.contentView.bounds.height)
        scroll.contentView.scroll(to: NSPoint(x: 0, y: document.isFlipped ? top : 0))
        scroll.reflectScrolledClipView(scroll.contentView)
    }

    /// Quits with Cmd-Q. The exit confirmation (shown while torrents transfer) is a modal alert whose own run
    /// loop does not service Swift tasks, so its Yes button is clicked from a timer.
    /// The process ends while this waits; reaching the end of the wait is a failure.
    static func quitThroughUI(_ d: UIDriver) async {
        d.log("quitting with Cmd-Q")
        d.afterCommon(2.5) {
            if let yes = d.find(role: "AXButton", label: "Yes").first {
                d.log("exit confirmation shown; clicking Yes")
                d.clickNow(yes)
            }
        }
        await d.command("q")
        await d.pause(20)
        d.log("FAIL: process still alive 20 s after Cmd-Q")
    }

    static func probe(_ d: UIDriver) async throws {
        try await waitRunning(d)
        _ = await d.wait(timeout: 20) { d.model.transfers.items.count == 2 }
        d.log("transfers: \(d.model.transfers.items.count)")
        await d.pause(2)
        for table in d.views(in: try mainWindow(d), classNameContains: "TableView").compactMap({ $0 as? NSTableView }) {
            d.log("pre table label=\(table.accessibilityLabel() ?? "-") rows=\(table.numberOfRows)")
        }
        try await selectTorrent(d, named: "uiverify-public.bin")
        let hide = try await d.require(role: "AXButton", label: "Hide Details", in: [try mainWindow(d)])
        await d.click(hide)
        await d.pause(2)
        d.log("panel collapsed (visible=\(d.model.gui.propertiesVisible)); now Trackers")
        try await showTrackersTab(d)
        d.log("trackers tab shown")
        let start = Date()
        let window = try mainWindow(d)
        for table in d.views(in: window, classNameContains: "TableView").compactMap({ $0 as? NSTableView }) {
            d.log("table \(table.accessibilityLabel() ?? "-") rows=\(table.numberOfRows) cols=\(table.numberOfColumns)")
        }
        d.log("view scan took \(Date().timeIntervalSince(start))")
        d.dump(window, maxLines: 200)
        d.log("dump took \(Date().timeIntervalSince(start))")
    }
}
#endif
