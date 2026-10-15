import SwiftUI

/// "Category" submenu: New…, Reset, then every category (checked when shared).
struct TransferCategoryMenu: View {
    let selection: TorrentSelection
    @Environment(AppModel.self) private var model

    var body: some View {
        Menu("Category", systemImage: Symbol.folder) {
            Button("New…", systemImage: Symbol.plus) { model.requestNewCategory(assignTo: selection.ids) }
            Button("Reset", systemImage: Symbol.xmark) { model.setCategory(selection.ids, "") }
            Divider()
            Picker("Category", selection: selection.categoryBinding) {
                ForEach(model.categories.sortedNames, id: \.self) { name in
                    Text(name).tag(Optional(name))
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }
}
