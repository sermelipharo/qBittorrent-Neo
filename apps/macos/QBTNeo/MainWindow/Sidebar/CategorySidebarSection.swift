import SwiftUI

/// CATEGORIES section with All / Uncategorized and the subcategory tree
/// (features.md §1.5.2). Torrents dropped on a category are assigned to it.
struct CategorySidebarSection: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        let counts = model.list.counts
        Section(isExpanded: $gui.categorySectionExpanded) {
            SidebarRow(title: String(localized: "All"), systemImage: Symbol.folder, count: counts.total)
                .tag(SidebarItem.category(.all))
                .contextMenu { CategoryContextMenu(category: nil) }
            SidebarRow(title: String(localized: "Uncategorized"), systemImage: Symbol.folderBadgeQuestionmark, count: counts.uncategorized)
                .tag(SidebarItem.category(.uncategorized))
                .contextMenu { CategoryContextMenu(category: nil) }
                .dropDestination(for: String.self) { items, _ in assign(items, to: "") }
            OutlineGroup(model.categories.tree, children: \.children) { node in
                SidebarRow(title: node.name, systemImage: Symbol.folderFill, count: counts.categories[node.id] ?? 0, tint: .accentColor)
                    .tag(SidebarItem.category(.category(node.id)))
                    .contextMenu { CategoryContextMenu(category: node.id) }
                    .dropDestination(for: String.self) { items, _ in assign(items, to: node.id) }
            }
        } header: {
            Text("Categories")
        }
        .onChange(of: gui.categorySectionExpanded) { _, expanded in
            if !expanded { model.list.categoryFilter = .all }
        }
    }

    private func assign(_ items: [String], to category: String) {
        let ids = TorrentDragPayload.decode(items)
        guard !ids.isEmpty else { return }
        model.setCategory(ids, category)
    }
}
