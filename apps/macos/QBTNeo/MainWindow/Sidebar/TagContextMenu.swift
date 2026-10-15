import SwiftUI

/// Tag filter context menu.
struct TagContextMenu: View {
    /// The right-clicked tag; nil for All / Untagged.
    let tag: String?
    @Environment(AppModel.self) private var model

    var body: some View {
        Button("Add Tag…", systemImage: "plus") { model.requestAddTag() }
        if let tag {
            Button("Remove Tag", systemImage: "minus.circle") { model.removeTag(tag) }
        }
        Button("Remove Unused Tags", systemImage: "trash.slash") { model.removeUnusedTags() }
        Divider()
        SidebarTorrentActions()
    }
}
