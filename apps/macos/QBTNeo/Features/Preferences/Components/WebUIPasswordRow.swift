import SwiftUI

/// "Password:" — empty keeps the current password; a new one (6+
/// characters) is hashed by the core when the field is committed.
struct WebUIPasswordRow: View {
    @Bindable var model: PreferencesModel
    @FocusState private var isFocused: Bool

    var body: some View {
        SecureField("Password:", text: $model.webUIPassword, prompt: Text("Change current password"))
            .focused($isFocused)
            .onSubmit(commit)
            .onChange(of: isFocused) { if !isFocused { commit() } }
        if let message = model.passwordMessage {
            InlineMessage(text: message.text, style: message.isError ? .error : .success)
        } else if let error = model.passwordRequiredError {
            InlineMessage(text: error)
        }
    }

    private func commit() {
        Task { await model.commitWebUIPassword() }
    }
}
