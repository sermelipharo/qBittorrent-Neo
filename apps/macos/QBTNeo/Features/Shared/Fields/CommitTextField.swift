import SwiftUI

/// A text field that edits a local copy and writes it back on Return or
/// when focus leaves, so settings apply on commit rather than per keystroke.
struct CommitTextField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    var prompt: String?
    var isSecure = false
    var trims = false

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        field
            .focused($isFocused)
            .onSubmit(commit)
            .onAppear { draft = text }
            .onChange(of: text) { if !isFocused { draft = text } }
            .onChange(of: isFocused) { if !isFocused { commit() } }
    }

    @ViewBuilder private var field: some View {
        if isSecure {
            SecureField(title, text: $draft, prompt: prompt.map { Text($0) })
        } else {
            TextField(title, text: $draft, prompt: prompt.map { Text($0) })
        }
    }

    private func commit() {
        let value = trims ? draft.trimmingCharacters(in: .whitespacesAndNewlines) : draft
        if value != text { text = value }
        if value != draft { draft = value }
    }
}
