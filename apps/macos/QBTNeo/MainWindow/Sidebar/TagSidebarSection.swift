import SwiftUI

/// TAGS section with All / Untagged (features.md §1.5.3). Torrents dropped
/// on a tag get that tag.
struct TagSidebarSection: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        let counts = model.list.counts
        Section(isExpanded: $gui.tagSectionExpanded) {
            SidebarRow(title: String(localized: "All"), systemImage: Symbol.tag, count: counts.total)
                .tag(SidebarItem.tag(.all))
                .contextMenu { TagContextMenu(tag: nil) }
            SidebarRow(title: String(localized: "Untagged"), systemImage: Symbol.tagSlash, count: counts.untagged)
                .tag(SidebarItem.tag(.untagged))
                .contextMenu { TagContextMenu(tag: nil) }
            ForEach(model.tags.sortedTags, id: \.self) { tag in
                SidebarRow(title: tag, systemImage: Symbol.tagFill, count: counts.tags[tag] ?? 0, tint: .orange)
                    .tag(SidebarItem.tag(.tag(tag)))
                    .contextMenu { TagContextMenu(tag: tag) }
                    .dropDestination(for: String.self) { items, _ in
                        let ids = TorrentDragPayload.decode(items)
                        guard !ids.isEmpty else { return }
                        model.perform { try $0.addTags(hashes: ids, tags: [tag]) }
                    }
            }
        } header: {
            Text("Tags")
        }
        .onChange(of: gui.tagSectionExpanded) { _, expanded in
            if !expanded { model.list.tagFilter = .all }
        }
    }
}
