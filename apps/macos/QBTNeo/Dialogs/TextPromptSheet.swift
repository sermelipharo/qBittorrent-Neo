import SwiftUI

/// Single-line prompt (rename, tracker/web seed URLs, tags); validation
/// errors keep it open and are shown inline.
struct TextPromptSheet: View {
    let request: TextPromptRequest
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        DialogContainer(title: LocalizedStringKey(request.title), confirmTitle: LocalizedStringKey(request.confirmTitle),
                        width: Design.Window.wideDialogWidth, onConfirm: submit) {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                Text(request.label)
                TextField(request.label, text: $text)
                    .labelsHidden()
                    .focused($focused)
                    .onSubmit(submit)
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(TorrentState.error.color)
                        .font(.callout)
                }
            }
        }
        .onAppear {
            text = request.text
            focused = true
        }
    }

    private func submit() {
        if let message = model.submit(request, text: text) {
            error = message
        } else {
            dismiss()
        }
    }
}
