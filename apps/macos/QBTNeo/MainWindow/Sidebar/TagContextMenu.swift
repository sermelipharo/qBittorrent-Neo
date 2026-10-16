import SwiftUI

/// Tag filter context menu.
struct TagContextMenu: View {
    /// The right-clicked tag; nil for All / Untagged.
    let tag: String?
    @Environment(AppModel.self) private var model

    var body: some View {
        Button("Add Tag…", systemImage: Symbol.plus) { model.requestAddTag() }
        if let tag {
            Button("Edit Tag…", systemImage: Symbol.pencil) { model.requestEditTag(tag) }
            Button("Remove Tag", systemImage: Symbol.minusCircle) { model.removeTag(tag) }
        }
        Button("Remove Unused Tags", systemImage: Symbol.trashSlash) { model.removeUnusedTags() }
        Divider()
        SidebarTorrentActions()
    }
}
