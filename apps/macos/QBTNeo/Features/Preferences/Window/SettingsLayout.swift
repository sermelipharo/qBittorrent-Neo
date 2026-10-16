import AppKit
import SwiftUI

/// Layout metrics of the Settings window (docs/design/settings-ia.md §4.2, §7).
enum SettingsLayout {
    /// Narrowest window: the form column plus its margins (wide enough for the longest English row).
    static let contentWidth = 720.0
    /// Width of the toolbar search field.
    static let searchFieldWidth = 180.0
    /// The search field plus the toolbar's insets and gaps.
    static let toolbarSearchAllowance = 210.0
    /// Width of a toolbar pane item beyond its label.
    static let toolbarItemPadding = 10.0

    /// Window width: the form column, or wider when the localized pane labels
    /// and the expanded search field need more room, so the pane toolbar never
    /// overflows into a chevron menu (HIG: the toolbar always shows the active pane).
    @MainActor static let windowWidth: Double = {
        let font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let items = SettingsPane.allCases.reduce(0.0) { width, pane in
            let label = (pane.title as NSString).size(withAttributes: [.font: font]).width
            return width + max(label, 32) + toolbarItemPadding
        }
        return max(contentWidth, (items + toolbarSearchAllowance).rounded(.up))
    }()
    /// Horizontal and vertical margins of a pane.
    static let margin = 20.0
    /// Widest a pane's column may be: the window minus its two margins.
    @MainActor static var columnWidth: Double { windowWidth - 2 * margin }
    /// Width of the centered list of search results.
    static let searchResultsWidth = 560.0
    /// Narrowest a pane's column may be, so text fields keep a usable width.
    static let minColumnWidth = 480.0
    /// Indentation of dependent rows under their parent checkbox.
    static let indent = 20.0
    /// Widest explanatory footnote in the controls column.
    static let footnoteWidth = 380.0
    /// Between a control and its footnote inside one row.
    static let footnoteSpacing = 4.0
    static let highlightRadius = 6.0
    static let highlightInset = 3.0
    /// Space above each section title.
    static let sectionSpacing = 10.0
    /// Tallest pane before it scrolls (the toolbar stays fixed): the screen's
    /// visible height minus the title bar and toolbar, at most 820 pt.
    @MainActor static var maxPaneHeight: Double {
        min((NSScreen.main?.visibleFrame.height ?? 800) - 120, 820)
    }
    static let minPaneHeight = 120.0
}
