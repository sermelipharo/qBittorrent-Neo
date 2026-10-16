import SwiftUI

/// Main window toolbar (features.md §1.2): add, remove, start/stop, queue
/// (when queueing is enabled) and options; the filter field is `.searchable`.
/// Buttons render from the command registry, like the menus.
struct MainToolbar: ToolbarContent {
    let model: AppModel

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            CommandToolbarButton(.addTorrentFile, model: model)
            CommandToolbarButton(.addTorrentLink, model: model)
        }
        ToolbarItemGroup {
            CommandToolbarButton(.remove, model: model)
        }
        ToolbarItemGroup {
            CommandToolbarButton(.start, model: model)
            CommandToolbarButton(.stop, model: model)
        }
        if model.queueingEnabled {
            ToolbarItemGroup {
                CommandToolbarButton(.queueTop, model: model)
                CommandToolbarButton(.queueUp, model: model)
                CommandToolbarButton(.queueDown, model: model)
                CommandToolbarButton(.queueBottom, model: model)
            }
        }
        ToolbarItem {
            CommandToolbarButton(.lock, model: model, label: String(localized: "Lock"))
        }
        ToolbarItem {
            CommandToolbarButton(.options, model: model)
        }
    }
}
