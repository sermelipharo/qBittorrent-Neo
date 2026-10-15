import SwiftUI

/// View ▸ "Lock qBittorrent Neo" (⌘L) with its "Set Password…" and
/// "Clear Password…" companions.
struct LockCommands: View {
    let model: AppModel
    let context: CommandContext

    var body: some View {
        CommandMenuItem(.lock, context: context)
        CommandMenuItem(.setLockPassword, context: context)
        Button("Clear Password…") { model.confirmation = .clearLockPassword }
            .disabled(!model.lock.hasPassword)
    }
}
