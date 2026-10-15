import Foundation

/// One row of the Command Palette.
struct PaletteItem: Identifiable {
    enum Action {
        /// A registry command on the selection (`targets` nil) or on the given torrents.
        case command(CommandID, targets: [String]?)
        /// Jump to a torrent (select it, scroll to it, clearing filters if needed).
        case torrent(String)
        case filter(SidebarItem)
        /// Open Settings on the setting's pane and highlight it.
        case setting(String)
        /// Assign a category ("" resets) / start "New…".
        case category(String, targets: [String])
        case newCategory(targets: [String])
        case toggleTag(String, targets: [String])
        case addTags(targets: [String])
        case removeAllTags(targets: [String])
    }

    /// Stable identity; also the key of recent items.
    let id: String
    let action: Action
    let title: String
    var subtitle: String?
    let symbol: String
    var shortcut: CommandShortcut?
    /// The on/off state of a toggle command, or the checkmark of a category/tag row.
    var isOn: Bool?
    /// Choosing it (or Tab, →) shows a nested list.
    var hasDetail = false
}
