import SwiftUI

/// A multi-line text editor (one entry per line) that writes its text back
/// when focus leaves, so lists apply as a whole rather than per keystroke.
/// `TextEditor` is used because Return must insert line breaks.
struct CommitTextEditor: View {
    let title: LocalizedStringKey
    @Binding var text: String
    var minHeight = 72.0
    var prompt: String?

    @State private var draft = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextEditor(text: $draft)
            .multilineTextAlignment(.leading)
            .font(.body.monospaced())
            .scrollContentBackground(.hidden)
            .padding(Design.Spacing.tight)
            .frame(minHeight: minHeight)
            .background(.background, in: .rect(cornerRadius: Design.Radius.medium))
            .overlay(alignment: .topLeading) {
                Text(prompt ?? "")
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, Design.Spacing.regular)
                    .padding(.vertical, Design.Spacing.tight)
                    .opacity(draft.isEmpty ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Design.Radius.medium)
                    .strokeBorder(.separator)
            }
            .focused($isFocused)
            .accessibilityLabel(Text(title))
            .onAppear { draft = text }
            .onChange(of: text) { if !isFocused { draft = text } }
            .onChange(of: isFocused) { if !isFocused, draft != text { text = draft } }
            .onDisappear { if draft != text { text = draft } }
    }
}
