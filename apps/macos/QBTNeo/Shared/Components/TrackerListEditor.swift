import SwiftUI

/// Multi-line tracker list editor (one URL per line, blank line = new tier).
struct TrackerListEditor: View {
    @Binding var text: String
    var minHeight = 160.0

    var body: some View {
        TextEditor(text: $text)
            .font(.body.monospaced())
            .autocorrectionDisabled()
            .scrollContentBackground(.hidden)
            .padding(Design.Spacing.tight)
            .background(.background, in: .rect(cornerRadius: Design.Radius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: Design.Radius.medium)
                    .stroke(.separator)
            }
            .frame(minHeight: minHeight)
            .accessibilityLabel(Text("Tracker URLs"))
    }
}
