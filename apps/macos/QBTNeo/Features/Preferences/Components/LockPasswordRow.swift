import SwiftUI

/// Privacy › App Lock "Lock password:" row: sets or clears the password that
/// ⌘L ("Lock qBittorrent Neo") asks for. Only the PBKDF2 hash is stored.
struct LockPasswordRow: View {
    @Environment(AppModel.self) private var app
    @State private var showsPasswordSheet = false
    @State private var confirmsClear = false

    var body: some View {
        LabeledContent(SettingsCatalog.key("Locking/password_PBKDF2")) {
            HStack {
                Button(app.lock.hasPassword ? "Change Password…" : "Set Password…") { showsPasswordSheet = true }
                Button("Clear Password…") { confirmsClear = true }
                    .disabled(!app.lock.hasPassword)
            }
        }
        .sheet(isPresented: $showsPasswordSheet) {
            LockPasswordSheet(lockAfterSaving: false)
                .environment(app)
        }
        .confirmationDialog("Clear the password", isPresented: $confirmsClear) {
            Button("Clear", role: .destructive) { app.clearLockPassword() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to clear the password?")
        }
    }
}
