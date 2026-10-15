import SwiftUI

/// Category filter context menu.
struct CategoryContextMenu: View {
    /// The right-clicked category; nil for All / Uncategorized.
    let category: String?
    @Environment(AppModel.self) private var model

    var body: some View {
        Button("Add Category…", systemImage: "plus") { model.requestNewCategory() }
        if let category {
            Button("Add Subcategory…", systemImage: "folder.badge.plus") { model.requestNewCategory(parent: category) }
            Button("Edit Category…", systemImage: "pencil") { model.requestEditCategory(category) }
            Button("Remove Category", systemImage: "minus.circle") { model.removeCategory(category) }
        }
        Button("Remove Unused Categories", systemImage: "trash.slash") { model.removeUnusedCategories() }
        Divider()
        SidebarTorrentActions()
    }
}
