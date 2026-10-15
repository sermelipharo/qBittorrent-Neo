import SwiftUI

/// Replaces a secondary window's content with a notice while the UI is
/// locked, so no window opened by any route can show session data.
struct LockGate: ViewModifier {
    @Environment(AppModel.self) private var model

    func body(content: Content) -> some View {
        if model.lock.isLocked {
            ContentUnavailableView("qBittorrent Neo is locked", systemImage: Symbol.lockFill,
                                   description: Text("Unlock it from the main window."))
                .frame(minWidth: 320, minHeight: 200)
        } else {
            content
        }
    }
}

extension View {
    func lockGated() -> some View {
        modifier(LockGate())
    }
}
