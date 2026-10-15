import SwiftUI

/// A sorted list of IP addresses or subnets with an entry field, Add and
/// Delete — the Banned IPs (§3.18) and IP subnet whitelist (§3.19) dialogs.
/// Saving happens only when the list was modified.
struct AddressListSheet: View {
    let title: LocalizedStringKey
    let prompt: String
    let addTitle: LocalizedStringKey
    let normalize: (String) -> String?
    let invalidMessage: String
    let duplicateMessage: String
    let initial: [String]
    let save: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var items: [String] = []
    @State private var selection: Set<String> = []
    @State private var entry = ""
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text(title)
                .font(.headline)
            List(items, id: \.self, selection: $selection) { item in
                Text(item)
                    .monospaced()
            }
            .listStyle(.bordered)
            .alternatingRowBackgrounds()
            .frame(minHeight: 200)
            .onDeleteCommand(perform: deleteSelected)
            HStack {
                TextField("Address", text: $entry, prompt: Text(prompt))
                    .labelsHidden()
                    .onSubmit(add)
                Button(addTitle, action: add)
                    .disabled(normalize(entry) == nil)
                Button("Delete", action: deleteSelected)
                    .disabled(selection.isEmpty)
            }
            if let error {
                InlineMessage(text: error)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("OK", action: confirm)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(width: FeatureDesign.Window.sheetWidth, height: 460)
        .onAppear { items = initial.sorted(using: KeyPathComparator(\.self)) }
    }

    private func add() {
        guard let value = normalize(entry) else {
            error = invalidMessage
            return
        }
        guard !items.contains(value) else {
            error = duplicateMessage
            return
        }
        items.append(value)
        items.sort(using: KeyPathComparator(\.self))
        entry = ""
        error = nil
    }

    private func deleteSelected() {
        items.removeAll { selection.contains($0) }
        selection = []
    }

    private func confirm() {
        if items != initial.sorted(using: KeyPathComparator(\.self)) { save(items) }
        dismiss()
    }
}
