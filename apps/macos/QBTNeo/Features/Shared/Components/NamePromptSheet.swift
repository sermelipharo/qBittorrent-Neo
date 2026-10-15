import SwiftUI

/// A one-line text prompt (qBittorrent's `AutoExpandableDialog`). The
/// confirm action returns whether the sheet may close.
struct NamePromptSheet: View {
    let title: LocalizedStringKey
    let label: LocalizedStringKey
    @State private var text: String
    let confirm: (String) async -> Bool
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    init(title: LocalizedStringKey, label: LocalizedStringKey, initial: String, confirm: @escaping (String) async -> Bool) {
        self.title = title
        self.label = label
        _text = State(initialValue: initial)
        self.confirm = confirm
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text(title)
                .font(.headline)
            TextField(label, text: $text)
                .focused($isFocused)
                .onSubmit(submit)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("OK", action: submit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(width: FeatureDesign.Window.sheetWidth)
        .onAppear { isFocused = true }
    }

    private func submit() {
        Task {
            if await confirm(text) { dismiss() }
        }
    }
}
