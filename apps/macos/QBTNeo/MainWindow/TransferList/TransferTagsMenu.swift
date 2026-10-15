import SwiftUI

/// "Tags" submenu: Add…, Remove All, then one tri-state entry per tag.
struct TransferTagsMenu: View {
    let selection: TorrentSelection
    @Environment(AppModel.self) private var model

    var body: some View {
        Menu("Tags", systemImage: Symbol.tag) {
            Button("Add…", systemImage: Symbol.plus) { model.requestAddTags(selection.ids) }
            Button("Remove All", systemImage: Symbol.xmark) { model.requestRemoveAllTags(selection.ids) }
            Divider()
            ForEach(model.tags.sortedTags, id: \.self) { tag in
                Toggle(tag, sources: selection.tagSources(tag), isOn: \.self)
            }
        }
    }
}
