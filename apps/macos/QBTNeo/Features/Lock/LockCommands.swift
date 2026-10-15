import SwiftUI

/// View ▸ "Lock qBittorrent Neo" (⌘L) with its "Set Password…" and
/// "Clear Password…" companions.
struct LockCommands: View {
    let model: AppModel

    var body: some View {
        Button("Lock qBittorrent Neo", systemImage: Symbol.lock) { model.requestLock() }
            .keyboardShortcut("l")
        Button("Set Password…") { model.sheet = .lockPassword(lockAfterSaving: false) }
        Button("Clear Password…") { model.confirmation = .clearLockPassword }
            .disabled(!model.lock.hasPassword)
    }
}
