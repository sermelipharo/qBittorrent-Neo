import SwiftUI

/// "Torrent Tags" (features.md §3.22): a check box per tag plus "+" to add
/// one; tags are created in the session only when used.
struct TagsPickerSheet: View {
    @Binding var tags: [String]
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var checked: Set<String> = []
    @State private var all: [String] = []
    @State private var newTag = ""
    @State private var error: String?

    var body: some View {
        DialogContainer(title: "Torrent Tags", onConfirm: save) {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Spacing.small) {
                    ForEach(all, id: \.self) { tag in
                        Toggle(tag, isOn: $checked[contains: tag])
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 180)
            HStack {
                TextField("New tag", text: $newTag)
                    .onSubmit(add)
                Button("Add", systemImage: "plus", action: add)
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let error {
                Text(error).foregroundStyle(TorrentState.error.color)
            }
        }
        .onAppear {
            checked = Set(tags)
            all = (Set(tags).union(model.tags.sortedTags)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        }
    }

    private func add() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        guard TagStore.isValid(tag) else {
            error = String(localized: "Tag name '\(tag)' is invalid.")
            return
        }
        guard !all.contains(tag) else {
            error = String(localized: "Tag name already exists.")
            return
        }
        all.append(tag)
        checked.insert(tag)
        newTag = ""
        error = nil
    }

    private func save() {
        tags = all.filter(checked.contains)
        dismiss()
    }
}
