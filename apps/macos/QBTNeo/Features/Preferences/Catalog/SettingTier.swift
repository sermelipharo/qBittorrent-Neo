import Foundation

/// Visibility tier of a setting (docs/design/settings-ia.md §4.3).
enum SettingTier {
    /// Always visible.
    case basic
    /// Shown, indented, while its basic parent is on or chosen.
    case revealed
    /// Inside a collapsed disclosure group of its section.
    case disclosure
    /// Visible while "Show advanced settings" is on (or revealed by search).
    case advanced
    /// libtorrent and internal tuning on the Advanced pane, behind the same switch.
    case expert
    /// API-only or derived key covered by another control; no row of its own.
    case hidden
    /// Not shown on macOS or with libtorrent 2.
    case platform

    /// Hidden while "Show advanced settings" is off.
    var needsAdvanced: Bool { self == .advanced || self == .expert }

    /// Has a row (and a search result) of its own.
    var hasRow: Bool { self != .hidden && self != .platform }
}
