import SwiftUI

/// What the main window shows while the UI is locked: a password prompt and
/// nothing else (the transfer list is not even in the view hierarchy).
struct UILockScreen: View {
    @Environment(AppModel.self) private var model
    @State private var password = ""
    @FocusState private var focused: Bool

    var body: some View {
        let lock = model.lock
        VStack(spacing: Design.Spacing.large) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("qBittorrent Neo is locked")
                .font(.title2)
            Text("Please type the UI lock password:")
                .foregroundStyle(.secondary)
            SecureField("Password", text: $password)
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)
                .focused($focused)
                .onSubmit(unlock)
                .disabled(lock.isBusy)
            if let error = lock.unlockError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(TorrentState.error.color)
                    .font(.callout)
            }
            Button("Unlock", action: unlock)
                .keyboardShortcut(.defaultAction)
                .disabled(password.isEmpty || lock.isBusy)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .onAppear { focused = true }
    }

    private func unlock() {
        let attempt = password
        password = ""
        Task {
            if await model.lock.unlock(with: attempt) { model.didUnlock() } else { focused = true }
        }
    }
}
