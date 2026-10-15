import SwiftUI

/// Category filter context menu.
struct CategoryContextMenu: View {
    /// The right-clicked category; nil for All / Uncategorized.
    let category: String?
    @Environment(AppModel.self) private var model

    var body: some View {
        Button("Add Category…", systemImage: Symbol.plus) { model.requestNewCategory() }
        if let category {
            Button("Add Subcategory…", systemImage: Symbol.folderBadgePlus) { model.requestNewCategory(parent: category) }
            Button("Edit Category…", systemImage: Symbol.pencil) { model.requestEditCategory(category) }
            Button("Remove Category", systemImage: Symbol.minusCircle) { model.removeCategory(category) }
        }
        Button("Remove Unused Categories", systemImage: Symbol.trashSlash) { model.removeUnusedCategories() }
        Divider()
        SidebarTorrentActions()
    }
}
