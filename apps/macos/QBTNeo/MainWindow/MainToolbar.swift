import SwiftUI

/// Main window toolbar (features.md §1.2): add, remove, start/stop, queue
/// (when queueing is enabled) and options; the filter field is `.searchable`.
/// Buttons render from the command registry, like the menus.
struct MainToolbar: ToolbarContent {
    let model: AppModel

    var body: some ToolbarContent {
        let context = CommandContext(selectionOf: model)
        ToolbarItemGroup(placement: .navigation) {
            CommandToolbarButton(.addTorrentFile, context: context)
            CommandToolbarButton(.addTorrentLink, context: context)
        }
        ToolbarItemGroup {
            CommandToolbarButton(.remove, context: context)
        }
        ToolbarItemGroup {
            CommandToolbarButton(.start, context: context)
            CommandToolbarButton(.stop, context: context)
        }
        if model.queueingEnabled {
            ToolbarItemGroup {
                CommandToolbarButton(.queueTop, context: context)
                CommandToolbarButton(.queueUp, context: context)
                CommandToolbarButton(.queueDown, context: context)
                CommandToolbarButton(.queueBottom, context: context)
            }
        }
        ToolbarItem {
            CommandToolbarButton(.lock, context: context, label: String(localized: "Lock"))
        }
        ToolbarItem {
            CommandToolbarButton(.options, context: context)
        }
    }
}
