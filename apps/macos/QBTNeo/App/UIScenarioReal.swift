#if DEBUG
import AppKit

/// Scenarios 5 and 6: real torrents from the public network, driven entirely through the UI.
extension UIScenarios {
    static var env: [String: String] { ProcessInfo.processInfo.environment }

    // MARK: Helpers

    static func current(_ d: UIDriver) -> TorrentItem? { d.model.transfers.items.first }

    static func fmtSpeed(_ bytes: Int64) -> String { String(format: "%.2f MiB/s", Double(bytes) / 1_048_576) }

    static func stateName(_ d: UIDriver) -> String { current(d).map { "\($0.state)" } ?? "none" }

    /// Column title -> visible text of the transfer table row of the only torrent.
    static func rowCells(_ d: UIDriver) -> [String: String] {
        guard let table = try? transferTable(d), table.numberOfRows > 0 else { return [:] }
        let texts = d.tableTexts(table)
        guard let row = texts.first else { return [:] }
        var result: [String: String] = [:]
        for (column, text) in zip(table.tableColumns, row) { result[column.title] = text }
        if result["Progress"]?.isEmpty ?? false, let window = table.window,
           let index = table.tableColumns.firstIndex(where: { $0.title == "Progress" }),
           let cell = table.view(atColumn: index, row: 0, makeIfNecessary: true) {
            result["Progress"] = anyValues(under: cell, d: d, window: window).joined(separator: " ")
        }
        return result
    }

    /// Values and labels of every accessibility element under `root` (progress bars carry their percentage there).
    static func anyValues(under root: NSObject, d: UIDriver, window: NSWindow, depth: Int = 0) -> [String] {
        guard depth < 10 else { return [] }
        let item = d.element(root, in: window)
        var found = [item.value, item.label].filter { !$0.isEmpty }
        for child in d.children(of: root) { found += anyValues(under: child, d: d, window: window, depth: depth + 1) }
        return found
    }

    /// Opens Torrent Options for the only torrent and sets its download limit (KiB/s) through the text field.
    static func setDownloadLimit(_ d: UIDriver, kib: Int, shotName: String) async throws {
        try await selectOnlyTorrent(d)
        let sheet = try await openTorrentOptions(d, named: current(d)?.name ?? "")
        scrollToBottom(d, sheet)
        let downloadField = field(d, in: sheet, labelled: "Download:")
        d.log("fields in sheet: \(d.elements(in: sheet).filter { $0.role == "AXTextField" }.map(\.description))")
        guard let downloadField else { throw UIDriver.Failure(description: "Download limit field not found") }
        await d.click(downloadField)
        await d.type(String(kib), window: sheet)
        await d.key("\t", code: 48, window: sheet)
        await d.shot(shotName)
        try await closeSheet(d, sheet, button: "OK")
        let applied = await waitForState(d, timeout: 15) { $0.dlLimit == Int64(kib) * 1024 }
        d.check(applied, "torrent download limit is \(current(d)?.dlLimit ?? -1) bytes/s (expected \(kib * 1024))")
    }

    static func logRow(_ d: UIDriver, _ tag: String) {
        let cells = rowCells(d)
        let keys = ["Progress", "Status", "Down Speed", "Up Speed", "ETA", "Seeds", "Peers", "Size"]
        let shown = keys.compactMap { key in cells[key].map { "\(key)='\($0)'" } }.joined(separator: " ")
        if let item = current(d) {
            let figures = "progress=\(String(format: "%.3f", item.progress)) dl=\(fmtSpeed(item.dlSpeed)) ul=\(fmtSpeed(item.upSpeed))"
            let peers = "conns=\(item.connectionsCount) seeds=\(item.numSeeds)/\(item.numComplete) peers=\(item.numLeechs)/\(item.numIncomplete)"
            d.log("\(tag): model state=\(item.state) \(figures) eta=\(item.eta) downloaded=\(item.downloaded) \(peers) | cells \(shown)")
        } else {
            d.log("\(tag): no torrent")
        }
    }

    /// Clicks a main-window toolbar item found by accessibility label or tooltip; falls back to `fallback`.
    static func clickToolbar(_ d: UIDriver, label: String, tooltipPrefix: String, fallback: @MainActor () -> Void) async throws {
        let window = try mainWindow(d)
        var candidates: [NSView] = []
        func visit(_ view: NSView, depth: Int) {
            guard depth < 30 else { return }
            let accessibility = view.accessibilityLabel() ?? ""
            let tip = view.toolTip ?? ""
            let title = (view as? NSButton)?.title ?? ""
            if !view.isHiddenOrHasHiddenAncestor, view.bounds.width > 0,
               accessibility == label || title == label || tip.hasPrefix(tooltipPrefix) {
                candidates.append(view)
            }
            for sub in view.subviews { visit(sub, depth: depth + 1) }
        }
        if let root = window.contentView?.superview { visit(root, depth: 0) }
        d.log("toolbar candidates for '\(label)': " + candidates.map { "\(Swift.type(of: $0)) tip='\($0.toolTip ?? "")'" }.joined(separator: "; "))
        // Prefer the actual button over a container carrying the same label.
        let target = candidates.first { $0 is NSControl } ?? candidates.last
        guard let target else {
            d.log("toolbar item '\(label)' not found in the view tree; using the model action (FALLBACK)")
            fallback()
            return
        }
        d.log("CLICK toolbar '\(label)' view \(Swift.type(of: target)) enabled=\((target as? NSControl)?.isEnabled ?? true)")
        await d.clickView(target, in: window)
        await d.pause(0.8)
    }

    static func tableView(_ d: UIDriver, columnPrefix: String, exactColumns: [String]? = nil) -> NSTableView? {
        guard let window = d.model.mainWindow else { return nil }
        let tables = d.views(in: window, classNameContains: "TableView").compactMap { $0 as? NSTableView }
        return tables.first { table in
            if let exactColumns { return table.tableColumns.map(\.title) == exactColumns }
            return table.tableColumns.contains { $0.title.hasPrefix(columnPrefix) }
        }
    }

    static func showTab(_ d: UIDriver, _ tab: PropertiesTab) async throws {
        let window = try mainWindow(d)
        if !(d.model.gui.propertiesVisible && d.model.gui.propertiesTab == tab) {
            let hide = d.find(role: "AXButton", label: "Hide Details", in: [window]).first
                ?? d.find(role: "AXButton", label: "Show Details", in: [window]).first
            let buttons = d.find(role: "AXButton", label: tab.title, in: [window])
            let button = hide.flatMap { hide in buttons.first { abs($0.frame.midY - hide.frame.midY) < 12 } } ?? buttons.first
            guard let button else { throw UIDriver.Failure(description: "tab button \(tab.title) not found") }
            await d.click(button)
        }
        let shown = await d.wait(timeout: 5) { d.model.gui.propertiesVisible && d.model.gui.propertiesTab == tab }
        d.check(shown, "\(tab.title) tab is showing")
        await d.pause(3)
    }

    static func texts(of table: NSTableView, d: UIDriver, limit: Int = 6) -> [String] {
        Array(d.tableTexts(table).map { $0.filter { !$0.isEmpty }.joined(separator: " | ") }.prefix(limit))
    }

    /// The text field next to a static text label (matched by vertical position) inside `window`.
    static func field(_ d: UIDriver, in window: NSWindow, labelled label: String) -> UIDriver.Element? {
        let all = d.elements(in: window)
        guard let text = all.first(where: { $0.role == "AXStaticText" && $0.value == label }) else { return nil }
        return all.first { $0.role == "AXTextField" && abs($0.frame.midY - text.frame.midY) < 14 }
    }

    /// Waits for the Add Torrent window's Add button, optionally for finished metadata, and confirms it.
    static func confirmAddDialog(_ d: UIDriver, shotName: String, expectMetadata: Bool) async throws {
        _ = try await d.require(role: "AXButton", label: "Add", timeout: 40)
        let started = Date()
        if expectMetadata {
            let got = await d.wait(timeout: 240) {
                d.find(role: "AXStaticText").contains { $0.value == "Metadata retrieval complete" }
            }
            d.check(got, "magnet metadata retrieved in the Add Torrent dialog after \(Int(Date().timeIntervalSince(started))) s")
        }
        await d.pause(1.5)
        if let add = d.find(role: "AXButton", label: "Add").first {
            let kinds = ["AXTextField", "AXStaticText", "AXComboBox"]
            let texts = d.elements(in: add.window).filter { kinds.contains($0.role) && !$0.value.isEmpty }.map(\.value)
            d.log("Add Torrent dialog '\(add.window.title)' texts: \(texts.prefix(40))")
        }
        await d.shot(shotName)
        let before = d.model.transfers.items.count
        for attempt in 1 ... 3 {
            guard let add = await d.settled(role: "AXButton", label: "Add") else { break }
            d.log("clicking Add (attempt \(attempt), enabled=\(add.enabled))")
            await d.click(add)
            if await d.wait(timeout: 4, { d.find(role: "AXButton", label: "Add").isEmpty }) { break }
        }
        let added = await d.wait(timeout: 20) { d.model.transfers.items.count > before }
        d.check(added, "torrent appears in the transfer list after Add")
    }

    @discardableResult
    static func selectOnlyTorrent(_ d: UIDriver) async throws -> TorrentItem {
        guard let name = current(d)?.name else { throw UIDriver.Failure(description: "no torrent to select") }
        return try await selectTorrent(d, named: name)
    }

    static func waitForState(_ d: UIDriver, timeout: Double, _ predicate: (TorrentItem) -> Bool) async -> Bool {
        await d.wait(timeout: timeout) { current(d).map(predicate) ?? false }
    }

    /// Samples the row (model + cells) `count` times, `interval` s apart.
    static func sampleRow(_ d: UIDriver, count: Int, interval: Double, tag: String) async -> (speedCells: Set<String>, speeds: [Int64], etas: Set<String>) {
        var progress = Set<String>()
        var speeds: [Int64] = []
        var etas = Set<String>()
        for index in 1 ... count {
            await d.pause(interval)
            logRow(d, "\(tag) sample \(index)")
            let cells = rowCells(d)
            if let value = cells["Down Speed"] { progress.insert(value) }
            if let value = cells["ETA"] { etas.insert(value) }
            speeds.append(current(d)?.dlSpeed ?? 0)
        }
        return (progress, speeds, etas)
    }

    // MARK: Scenario 5: Big Buck Bunny

    static func bunny(_ d: UIDriver) async throws {
        try await waitRunning(d)
        d.check(d.model.transfers.items.isEmpty, "profile starts without torrents")
        guard let magnet = env["QBT_UI_MAGNET"], !magnet.isEmpty else { throw UIDriver.Failure(description: "QBT_UI_MAGNET not set") }

        // 1. Add Torrent Link dialog, typed into the text area.
        d.model.sheet = .addLinks(initialText: "")
        let editor = try await d.require(role: "AXTextArea", timeout: 15)
        await d.pause(0.8)
        await d.click(editor)
        // An inactive app does not focus the text view on a click; focus it directly, then type into the sheet.
        if let textView = d.views(in: editor.window, classNameContains: "TextView").compactMap({ $0 as? NSTextView }).first {
            d.log("focusing \(Swift.type(of: textView)) (first responder before: \(Swift.type(of: editor.window.firstResponder as Any)))")
            editor.window.makeFirstResponder(textView)
        }
        await d.typeFast(magnet, window: editor.window)
        let typed = d.find(role: "AXTextArea").first?.value ?? ""
        d.check(typed == magnet, "link text area holds the full magnet link (\(typed.count) of \(magnet.count) characters)")
        if typed != magnet { d.log("typed text: \(typed)") }
        await d.shot("bbb-link-typed")
        let download = try await d.require(role: "AXButton", label: "Download", timeout: 10)
        await d.click(download)
        d.check(await d.wait(timeout: 8) { d.find(role: "AXTextArea").isEmpty }, "Add Torrent Links sheet closed")

        // 2. Add Torrent dialog (metadata retrieval for the magnet), then Add.
        try await confirmAddDialog(d, shotName: "bbb-add-dialog", expectMetadata: true)
        _ = await waitForState(d, timeout: 60) { $0.hasMetadata }
        d.log("torrent name: \(current(d)?.name ?? "?") savePath=\(current(d)?.savePath ?? "?")")
        await d.pause(2)
        try await selectOnlyTorrent(d)
        await d.shot("bbb-added")
        // Real swarms finish 276 MB in under a minute; throttle through the UI so the controls can be exercised mid-download.
        try await setDownloadLimit(d, kib: Int(env["QBT_UI_LIMIT_KIB"] ?? "1500") ?? 1500, shotName: "bbb-limit-typed")

        // 3. Progress, speed and ETA cells update.
        let downloading = await waitForState(d, timeout: 240) { $0.dlSpeed > 0 || $0.progress > 0.01 }
        d.check(downloading, "download started (speed or progress above zero)")
        let sampled = await sampleRow(d, count: 6, interval: 5, tag: "bbb")
        d.check(sampled.speedCells.count >= 3, "Down Speed cell texts changed across samples: \(sampled.speedCells.sorted())")
        d.check(sampled.speeds.contains { $0 > 0 }, "Down Speed above zero in samples: \(sampled.speeds.map(fmtSpeed))")
        d.check(!sampled.etas.isEmpty && sampled.etas != ["∞"], "ETA cell populated: \(sampled.etas.sorted())")
        await d.shot("bbb-downloading")

        // 4. Peers, Trackers, HTTP Sources and Content tabs.
        try await showTab(d, .peers)
        _ = await d.wait(timeout: 60) { (tableView(d, columnPrefix: "IP/Address")?.numberOfRows ?? 0) > 0 }
        let peers = tableView(d, columnPrefix: "IP/Address")
        d.log("Peers tab rows=\(peers?.numberOfRows ?? -1): \(peers.map { texts(of: $0, d: d) } ?? [])")
        d.check((peers?.numberOfRows ?? 0) > 0, "Peers tab populated (\(peers?.numberOfRows ?? 0) peers)")
        await d.shot("bbb-peers")
        try await showTab(d, .trackers)
        let trackers = tableView(d, columnPrefix: "URL")
        d.log("Trackers tab rows=\(trackers?.numberOfRows ?? -1): \(trackers.map { texts(of: $0, d: d, limit: 20) } ?? [])")
        d.check((trackers?.numberOfRows ?? 0) > 3, "Trackers tab populated (\(trackers?.numberOfRows ?? 0) rows)")
        await d.shot("bbb-trackers")
        try await showTab(d, .httpSources)
        _ = await d.wait(timeout: 30) { !d.model.properties.webSeeds.isEmpty }
        d.log("model web seeds: \(d.model.properties.webSeeds.map(\.url)); magnet URI: \(current(d)?.magnetURI ?? "")")
        let web = tableView(d, columnPrefix: "", exactColumns: ["URL"])
        d.log("HTTP Sources tab rows=\(web?.numberOfRows ?? -1): \(web.map { texts(of: $0, d: d) } ?? [])")
        d.check((web?.numberOfRows ?? 0) > 0, "HTTP Sources tab populated (\(web?.numberOfRows ?? 0) web seeds)")
        await d.shot("bbb-httpsources")
        try await showTab(d, .content)
        let content = tableView(d, columnPrefix: "Download Priority")
        d.log("Content tab rows=\(content?.numberOfRows ?? -1): \(content.map { texts(of: $0, d: d) } ?? [])")
        d.check((content?.numberOfRows ?? 0) > 0, "Content tab populated (\(content?.numberOfRows ?? 0) rows)")
        await d.shot("bbb-content")

        // 5. Change a file priority in the Content tab through its context menu.
        if let content, content.numberOfRows > 0 {
            let rows = texts(of: content, d: d, limit: 20)
            let row = rows.firstIndex { $0.contains(".mp4") } ?? 0
            await d.clickRow(content, row: row)
            let before = rows[row]
            let chose = await d.contextMenuPerform(table: content, row: row, path: ["Priority", "High"])
            d.check(chose, "Content context menu Priority > High chosen")
            await d.pause(3)
            let after = texts(of: content, d: d, limit: 20)[row]
            d.log("content row \(row) before: \(before)")
            d.log("content row \(row) after:  \(after)")
            let node = d.model.properties.files.rows.first { $0.name == "Big Buck Bunny.mp4" }
            d.check(node?.priority == .high, "file 'Big Buck Bunny.mp4' has High priority in the tree (\(String(describing: node?.priority)))")
            await d.shot("bbb-priority-high")
        }

        // 6. Pause and resume with the toolbar.
        try await selectOnlyTorrent(d)
        let ids = d.model.list.selectedIDs
        try await clickToolbar(d, label: "Stop", tooltipPrefix: "Stop the selected") { d.model.stop(ids) }
        let stopped = await waitForState(d, timeout: 15) { $0.state.isStopped }
        d.check(stopped, "toolbar Stop paused the torrent (state \(stateName(d)))")
        await d.pause(3)
        logRow(d, "bbb paused")
        d.check((current(d)?.dlSpeed ?? 1) == 0, "download speed is zero while paused")
        await d.shot("bbb-paused")
        let progressPaused = current(d)?.progress ?? 0
        try await clickToolbar(d, label: "Start", tooltipPrefix: "Start the selected") { d.model.start(ids) }
        let resumed = await waitForState(d, timeout: 30) { !$0.state.isStopped }
        d.check(resumed, "toolbar Start resumed the torrent (state \(stateName(d)))")
        let moving = await waitForState(d, timeout: 90) { $0.progress > progressPaused + 0.002 || $0.dlSpeed > 0 }
        d.check(moving, "download continued after resume")

        // 7. Force recheck (confirmation dialog); progress must be preserved.
        let progressBefore = current(d)?.progress ?? 0
        let index = try rowIndex(d, named: current(d)?.name ?? "")
        let recheck = await d.contextMenuPerform(table: try transferTable(d), row: index, title: "Force Recheck")
        d.check(recheck, "context menu Force Recheck chosen")
        if let confirm = try? await d.require(role: "AXButton", label: "Recheck", timeout: 8) {
            await d.shot("bbb-recheck-confirm")
            await d.click(confirm)
        } else {
            for window in NSApp.windows where window.isVisible && window.alphaValue > 0 { d.dump(window, maxLines: 40) }
        }
        let checking = await waitForState(d, timeout: 20) { $0.state.isChecking }
        d.log("saw checking state: \(checking)")
        let rechecked = await waitForState(d, timeout: 180) { !$0.state.isChecking && $0.progress > 0 }
        logRow(d, "bbb after recheck")
        let progressAfter = current(d)?.progress ?? 0
        d.check(rechecked && progressAfter >= progressBefore - 0.03,
                "recheck finished with progress preserved (\(String(format: "%.3f", progressBefore)) -> \(String(format: "%.3f", progressAfter)))")

        // 8. Finish the download and reach seeding, with the completion notification logged.
        var lastLog = Date()
        let finished = await d.wait(timeout: 2400) {
            if Date().timeIntervalSince(lastLog) > 30 { lastLog = Date(); logRow(d, "bbb waiting") }
            return (current(d)?.progress ?? 0) >= 1
        }
        d.check(finished, "download completed (progress \(String(format: "%.3f", current(d)?.progress ?? 0)))")
        let seeding = await waitForState(d, timeout: 60) { [.uploading, .stalledUploading, .forcedUploading].contains($0.state) }
        logRow(d, "bbb final")
        d.check(seeding, "torrent reached Seeding (state \(stateName(d)))")
        await d.pause(2)
        await d.shot("bbb-seeding")
        let files = (try? FileManager.default.subpathsOfDirectory(atPath: current(d)?.savePath ?? "")) ?? []
        d.log("files in the save path: \(files.prefix(20))")
        await quitThroughUI(d)
    }

    // MARK: Remove dialog probe

    /// Second launch on a profile that still has a torrent: removes it through the toolbar and the dialog's Remove button.
    static func removeProbe(_ d: UIDriver) async throws {
        try await waitRunning(d)
        _ = await d.wait(timeout: 10) { d.model.transfers.items.count == 1 }
        if d.model.transfers.items.isEmpty, let path = torrentPaths.first {
            d.model.open([URL(filePath: path)])
            try await confirmAddDialog(d, shotName: "probe-add", expectMetadata: false)
        }
        d.check(d.model.transfers.items.count == 1, "one torrent in the list")
        await d.pause(2)
        try await selectOnlyTorrent(d)
        let ids = d.model.list.selectedIDs
        if env["QBT_UI_BISECT"] == "1" {
            d.log("bisect: speed limits sheet")
            d.model.sheet = .speedLimits
            await d.pause(3)
            d.model.sheet = nil
            await d.pause(2)
            d.log("bisect: remove sheet through the model, properties tab \(d.model.gui.propertiesTab)")
            d.model.requestRemove(ids)
            await d.pause(4)
            d.log("bisect: remove sheet survived")
            d.model.sheet = nil
            await d.pause(2)
        }
        try await clickToolbar(d, label: "Remove", tooltipPrefix: "Remove the selected") { d.model.requestRemove(ids) }
        let toggle = try await d.require(role: "AXCheckBox", labelContains: "content files", timeout: 10)
        d.log("toggle value \(toggle.value)")
        await d.pause(1)
        let remove = try await d.require(role: "AXButton", label: "Remove", timeout: 5)
        d.log("Remove button \(remove.description) class \(Swift.type(of: remove.object))")
        await d.click(remove)
        var closed = await d.wait(timeout: 4) { d.find(role: "AXCheckBox", labelContains: "content files").isEmpty }
        d.log("after plain click: dialog closed=\(closed) torrents=\(d.model.transfers.items.count)")
        if !closed {
            await d.clickDirect(remove)
            closed = await d.wait(timeout: 4) { d.find(role: "AXCheckBox", labelContains: "content files").isEmpty }
            d.log("after direct click: dialog closed=\(closed) torrents=\(d.model.transfers.items.count)")
        }
        if !closed {
            d.log("pressing Remove through accessibility")
            _ = remove.object.perform(NSSelectorFromString("accessibilityPerformPress"))
            closed = await d.wait(timeout: 6) { d.find(role: "AXCheckBox", labelContains: "content files").isEmpty }
            d.log("after AXPress: dialog closed=\(closed) torrents=\(d.model.transfers.items.count)")
        }
        _ = await d.wait(timeout: 20) { d.model.transfers.items.isEmpty }
        d.check(d.model.transfers.items.isEmpty, "torrent removed from the list")
        await d.pause(3)
        await quitThroughUI(d)
    }

    // MARK: Scenario 6: Ubuntu

    static func ubuntu(_ d: UIDriver) async throws {
        try await waitRunning(d)
        d.check(d.model.transfers.items.isEmpty, "profile starts without torrents")
        guard let path = torrentPaths.first else { throw UIDriver.Failure(description: "QBT_UI_TORRENT not set") }
        let targetBytes = (Int64(env["QBT_UI_TARGET_MB"] ?? "320") ?? 320) * 1_048_576

        // 1. Open the .torrent like Finder does, confirm the Add Torrent dialog.
        d.model.open([URL(filePath: path)])
        try await confirmAddDialog(d, shotName: "ubuntu-add-dialog", expectMetadata: false)
        await d.pause(2)
        let item = try await selectOnlyTorrent(d)
        d.log("torrent \(item.name) size=\(item.size) savePath=\(current(d)?.savePath ?? "?")")
        await d.shot("ubuntu-added")

        // 2. Peers from DHT and trackers.
        let gotPeers = await d.wait(timeout: 180) { (current(d)?.connectionsCount ?? 0) > 0 }
        d.check(gotPeers, "connected to peers (connections \(current(d)?.connectionsCount ?? 0))")
        try await showTab(d, .trackers)
        let trackers = tableView(d, columnPrefix: "URL")
        d.log("Trackers tab rows: \(trackers.map { texts(of: $0, d: d, limit: 20) } ?? [])")
        try await showTab(d, .peers)
        _ = await d.wait(timeout: 60) { (tableView(d, columnPrefix: "IP/Address")?.numberOfRows ?? 0) > 0 }
        let peers = tableView(d, columnPrefix: "IP/Address")
        d.log("Peers tab rows=\(peers?.numberOfRows ?? -1): \(peers.map { texts(of: $0, d: d, limit: 12) } ?? [])")
        d.check((peers?.numberOfRows ?? 0) > 0, "Peers tab lists \(peers?.numberOfRows ?? 0) peers")
        await d.shot("ubuntu-peers")

        // 3. Sequential and first/last piece through the context menu.
        let table = try transferTable(d)
        var row = try rowIndex(d, named: current(d)?.name ?? "")
        _ = await d.contextMenuPerform(table: table, row: row, title: "Download in Sequential Order")
        let seq = await waitForState(d, timeout: 15) { $0.sequentialDownload }
        d.check(seq, "sequential download is on")
        row = try rowIndex(d, named: current(d)?.name ?? "")
        _ = await d.contextMenuPerform(table: table, row: row, title: "Download First and Last Pieces First")
        let firstLast = await waitForState(d, timeout: 15) { $0.firstLastPiecePriority }
        d.check(firstLast, "first and last pieces first is on")
        await d.shot("ubuntu-sequential")

        // 4. Download unlimited up to the target.
        var lastLog = Date()
        var peak: Int64 = 0
        let reached = await d.wait(timeout: 1500) {
            peak = max(peak, current(d)?.dlSpeed ?? 0)
            if Date().timeIntervalSince(lastLog) > 5 { lastLog = Date(); logRow(d, "ubuntu unlimited") }
            return (current(d)?.downloaded ?? 0) >= targetBytes
        }
        logRow(d, "ubuntu at target")
        d.check(reached, "downloaded \((current(d)?.downloaded ?? 0) / 1_048_576) MiB, peak speed \(fmtSpeed(peak))")
        await d.shot("ubuntu-unlimited")

        // 5. Download rate limit through Torrent Options.
        let limitKiB = Int(env["QBT_UI_LIMIT_KIB"] ?? "800") ?? 800
        try await setDownloadLimit(d, kib: limitKiB, shotName: "ubuntu-limit-typed")

        // 6. Measure the speed with the limit: per-interval byte deltas, transient then steady state.
        let limitBytes = Double(limitKiB * 1024)
        var last = (time: Date(), bytes: current(d)?.downloaded ?? 0)
        let began = last.time
        var deltas: [(at: Double, rate: Double)] = []
        for _ in 1 ... 90 {
            await d.pause(2)
            let now = (time: Date(), bytes: current(d)?.downloaded ?? 0)
            let rate = Double(now.bytes - last.bytes) / now.time.timeIntervalSince(last.time)
            deltas.append((now.time.timeIntervalSince(began), rate))
            last = now
            let elapsed = Int(now.time.timeIntervalSince(began))
            let cell = rowCells(d)["Down Speed"] ?? ""
            d.log("ubuntu limited t=\(elapsed) s: \(Int(rate / 1024)) KiB/s by bytes, model \(fmtSpeed(current(d)?.dlSpeed ?? 0)), cell '\(cell)'")
        }
        let settled = deltas.first { $0.rate <= limitBytes * 1.25 }?.at ?? -1
        let steady = deltas.filter { $0.at >= 120 }
        let averaged = steady.map(\.rate).reduce(0, +) / Double(max(steady.count, 1))
        let top = steady.map(\.rate).max() ?? 0
        let steadySummary = "average \(Int(averaged / 1024)) KiB/s, max \(Int(top / 1024)) KiB/s"
        d.log("limited: transient above 1.25x limit until t=\(Int(settled)) s; steady (t>=120 s) \(steadySummary); limit \(limitKiB) KiB/s")
        let withinLimit = averaged <= limitBytes * 1.1 && averaged >= limitBytes * 0.4
        d.check(withinLimit, "steady-state average \(Int(averaged / 1024)) KiB/s respects the \(limitKiB) KiB/s limit")
        d.check(steady.allSatisfy { $0.rate <= limitBytes * 1.5 }, "no steady-state interval far above the limit (max \(Int(top / 1024)) KiB/s)")
        await d.shot("ubuntu-limited")

        // 7. Remove with files through the toolbar and the remove dialog.
        let savePath = current(d)?.savePath ?? ""
        let contentPath = current(d)?.contentPath ?? ""
        let before = (try? FileManager.default.contentsOfDirectory(atPath: savePath)) ?? []
        d.log("before removal: savePath=\(savePath) contentPath=\(contentPath) entries=\(before)")
        try await selectOnlyTorrent(d)
        let ids = d.model.list.selectedIDs
        try await clickToolbar(d, label: "Remove", tooltipPrefix: "Remove the selected") { d.model.requestRemove(ids) }
        let toggle = try await d.require(role: "AXCheckBox", labelContains: "content files", timeout: 10)
        d.log("remove dialog toggle: \(toggle.description)")
        if toggle.value != "1" { await d.click(toggle) }
        await d.shot("ubuntu-remove-dialog")
        let toggled = d.find(role: "AXCheckBox", labelContains: "content files").first
        d.check(toggled?.value == "1", "'Also remove the content files' is on")
        for attempt in 1 ... 4 {
            guard let remove = await d.settled(role: "AXButton", label: "Remove", timeout: 5) else { break }
            d.log("clicking Remove (attempt \(attempt), enabled=\(remove.enabled))")
            await d.click(remove)
            if await d.wait(timeout: 4, { d.find(role: "AXCheckBox", labelContains: "content files").isEmpty }) { break }
            if attempt == 3 {
                d.log("FALLBACK: mouse click on the destructive Remove button had no effect; pressing it through accessibility")
                _ = remove.object.perform(NSSelectorFromString("accessibilityPerformPress"))
            }
        }
        let gone = await d.wait(timeout: 30) { d.model.transfers.items.isEmpty }
        d.check(gone, "torrent removed from the list")
        await d.pause(3)
        let after = ((try? FileManager.default.subpathsOfDirectory(atPath: savePath)) ?? []).filter { !$0.hasSuffix(".DS_Store") }
        d.log("after removal entries in \(savePath): \(after)")
        d.check(!FileManager.default.fileExists(atPath: contentPath) && after.allSatisfy { !$0.contains("ubuntu") }, "downloaded data is gone from disk")
        await d.shot("ubuntu-removed")
        await quitThroughUI(d)
    }
}
#endif
