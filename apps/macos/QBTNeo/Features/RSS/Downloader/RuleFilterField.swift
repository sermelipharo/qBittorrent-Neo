import SwiftUI

/// A rule text filter with a validity icon; invalid text turns red.
struct RuleFilterField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    let error: String
    let help: String
    var prompt: String?

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: Design.Spacing.small) {
                CommitTextField(title: title, text: $text, prompt: prompt)
                    .labelsHidden()
                    .foregroundStyle(error.isEmpty ? Color.primary : Color.red)
                Image(systemName: error.isEmpty ? "checkmark.circle" : "exclamationmark.triangle.fill")
                    .foregroundStyle(error.isEmpty ? Color.secondary : Color.orange)
                    .opacity(text.isEmpty ? 0 : 1)
                    .help(error.isEmpty ? String(localized: "Valid") : error)
                    .accessibilityLabel(error.isEmpty ? "Valid" : error)
            }
        }
        .help(help)
    }
}
