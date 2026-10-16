#if DEBUG
import AppKit

/// Live-run scenarios for category/tag icons and colors and "Color by state:" (use with `--demo` and a scratch
/// `--profile`). "live-labels-set" checks the migration of the former coloring settings (write
/// `GUI/TransferList/UseTorrentStatesColors = false` into the profile first), then sets a tag's and a category's
/// icon and color through their editors and removes a tag; "live-labels-verify" runs after a relaunch and checks
/// that everything persisted.
extension UIScenarios {
    static let labelsTag = "favorite"
    static let labelsCategory = "Movies"

    static func liveLabelsSet(_ d: UIDriver) async throws {
        try await waitRunning(d)
        d.log("Color by state after launch: \(d.model.gui.stateColorScope)")
        d.check(d.model.gui.stateColorScope == .off, "colored text off in the old settings migrated to None")
        d.model.gui.stateColorScope = .status

        // Tag: icon from a symbol search, purple swatch.
        d.model.requestEditTag(labelsTag)
        let sheet = try await requireSheet(d)
        try await pickSymbol(d, sheet: sheet, query: "game", symbol: "gamecontroller.fill")
        try await clickSwatch(d, sheet: sheet, title: "Purple")
        await d.shot("labels-tag-editor")
        try await confirmSheet(d, sheet)
        let tag = d.model.labels.tag(labelsTag)
        d.check(tag.symbol == "gamecontroller.fill" && tag.color == .system(.purple), "tag editor saved icon and color (\(tag))")

        // Category: green swatch and the curated film icon.
        guard let movies = d.model.categories.category(named: labelsCategory) else { throw UIDriver.Failure(description: "no Movies category") }
        d.model.requestEditCategory(movies.name)
        let categorySheet = try await requireSheet(d)
        try await pickSymbol(d, sheet: categorySheet, query: nil, symbol: "film.fill")
        try await clickSwatch(d, sheet: categorySheet, title: "Green")
        await d.shot("labels-category-editor")
        try await confirmSheet(d, categorySheet)
        let category = d.model.labels.category(labelsCategory)
        d.check(category.symbol == "film.fill" && category.color == .system(.green), "category editor saved icon and color (\(category))")
        let child = d.model.categories.sortedNames.first { $0.hasPrefix(labelsCategory + "/") }
        if let child {
            let inherited = d.model.labels.category(child)
            d.check(inherited.symbol == "film.fill" && inherited.color == .system(.green), "subcategory \(child) shows its parent's look")
        }

        // Removing a tag forgets its look.
        d.model.labels.setTag("work", LabelAppearance(symbol: "briefcase.fill", color: .system(.teal)))
        d.model.removeTag("work")
        _ = await d.wait(timeout: 5) { !d.model.tags.contains("work") }
        d.check(d.model.labels.tags["work"] == nil, "removing a tag removed its icon and color")
        await d.shot("labels-main")
    }

    static func liveLabelsVerify(_ d: UIDriver) async throws {
        try await waitRunning(d)
        let tag = d.model.labels.tag(labelsTag)
        let category = d.model.labels.category(labelsCategory)
        d.check(tag.symbol == "gamecontroller.fill" && tag.color == .system(.purple), "tag look survived the relaunch (\(tag))")
        d.check(category.symbol == "film.fill" && category.color == .system(.green), "category look survived the relaunch (\(category))")
        d.check(d.model.labels.tags["work"] == nil, "the removed tag stayed forgotten")
        d.check(d.model.gui.stateColorScope == .status, "Color by state survived the relaunch (\(d.model.gui.stateColorScope))")
        // Checked in a new process: the migration removed the former keys from the profile.
        let leftovers = [GUIPreferenceKey.legacyUseTorrentStatesColors, .legacyProgressBarFollowsTextColor]
            .compactMap { key in d.model.gui.defaults.object(forKey: key.rawValue).map { "\(key.rawValue)=\($0)" } }
        d.check(leftovers.isEmpty, "the former coloring keys are gone after migrating (left: \(leftovers))")
        await d.shot("labels-relaunched")
    }

    // MARK: Helpers

    private static func requireSheet(_ d: UIDriver) async throws -> NSWindow {
        _ = await d.wait(timeout: 5) { sheetWindow(d) != nil }
        guard let sheet = sheetWindow(d) else { throw UIDriver.Failure(description: "editor sheet did not open") }
        await d.pause(0.6)
        return sheet
    }

    private static func pickSymbol(_ d: UIDriver, sheet: NSWindow, query: String?, symbol: String) async throws {
        let button = try await d.require(identifier: "label-icon-button", in: [sheet])
        await d.click(button)
        _ = await d.wait(timeout: 5) { popoverWindow(d) != nil }
        guard let popover = popoverWindow(d) else { throw UIDriver.Failure(description: "symbol picker did not open") }
        if let query {
            let field = try await d.require(role: "AXTextField", in: [popover])
            await d.click(field)
            await d.type(query, window: popover)
            await d.pause(0.6)
        }
        let cell = try await d.require(role: "AXButton", label: symbol, in: [popover], timeout: 5)
        await d.click(cell)
        _ = await d.wait(timeout: 3) { d.find(role: "AXButton", label: symbol).isEmpty }
    }

    private static func popoverWindow(_ d: UIDriver) -> NSWindow? {
        d.windows.first { String(describing: type(of: $0)).contains("Popover") }
    }

    private static func clickSwatch(_ d: UIDriver, sheet: NSWindow, title: String) async throws {
        let swatch = try await d.require(role: "AXButton", label: title, in: [sheet])
        await d.click(swatch)
    }

    private static func confirmSheet(_ d: UIDriver, _ sheet: NSWindow) async throws {
        let ok = try await d.require(role: "AXButton", label: "OK", in: [sheet])
        await d.click(ok)
        let closed = await d.wait(timeout: 5) { sheetWindow(d) == nil }
        d.check(closed, "editor closed with OK")
    }
}
#endif
