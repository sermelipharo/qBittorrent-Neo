import SwiftUI

/// The "Torrent Tags" dialog (features.md §3.22): a checkbox per known tag
/// plus a field to add new ones (created in the session only when used).
struct TorrentTagsSheet: View {
    @Binding var selected: [String]
    let sessionTags: [String]
    @Environment(\.dismiss) private var dismiss

    @State private var checked: Set<String> = []
    @State private var extraTags: [String] = []
    @State private var newTag = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text("Torrent Tags")
                .font(.headline)
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], alignment: .leading) {
                    ForEach(allTags, id: \.self) { tag in
                        Toggle(tag, isOn: $checked[contains: tag])
                            .toggleStyle(.checkbox)
                    }
                }
            }
            .frame(minHeight: 80, maxHeight: 220)
            .overlay {
                if allTags.isEmpty {
                    Text("No tags yet")
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                TextField("Tag:", text: $newTag, prompt: Text("New tag"))
                    .onSubmit(addTag)
                Button("Add Tag", systemImage: "plus", action: addTag)
                    .labelStyle(.iconOnly)
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let error {
                InlineMessage(text: error)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("OK", action: accept)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(width: FeatureDesign.Window.sheetWidth)
        .onAppear { checked = Set(selected) }
    }

    private var allTags: [String] {
        Array(Set(selected).union(sessionTags).union(extraTags)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty else { return }
        if tag.contains(",") {
            error = String(localized: "Tag name '\(tag)' is invalid.")
            return
        }
        if allTags.contains(tag) {
            error = String(localized: "Tag name already exists.")
            return
        }
        extraTags.append(tag)
        checked.insert(tag)
        newTag = ""
        error = nil
    }

    private func accept() {
        selected = allTags.filter(checked.contains)
        dismiss()
    }
}
