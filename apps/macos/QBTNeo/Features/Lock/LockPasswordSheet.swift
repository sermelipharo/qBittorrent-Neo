import SwiftUI

/// "UI lock password" prompt (features.md §1.3.6). When opened by the Lock
/// action the UI locks as soon as the password is saved.
struct LockPasswordSheet: View {
    let lockAfterSaving: Bool
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        DialogContainer(title: "UI lock password", confirmTitle: "OK", isConfirmDisabled: model.lock.isBusy, onConfirm: submit) {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                Text("Please type the UI lock password:")
                SecureField("Password", text: $password)
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
        .onAppear { focused = true }
    }

    private func submit() {
        Task {
            if let message = await model.lock.setPassword(password) {
                error = message
                return
            }
            dismiss()
            if lockAfterSaving { model.lockUI() }
        }
    }
}
