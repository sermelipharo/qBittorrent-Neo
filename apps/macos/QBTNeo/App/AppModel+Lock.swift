import AppKit

/// UI lock actions (features.md §1.3.6).
extension AppModel {
    /// "Lock": asks for a password first when none is set (cancelling aborts).
    func requestLock() {
        guard !lock.isLocked else { return }
        if lock.hasPassword {
            lockUI()
        } else {
            sheet = .lockPassword(lockAfterSaving: true)
        }
    }

    /// Locks and hides everything: open sheets and prompts are dismissed and
    /// every other window is closed, so only the unlock prompt remains.
    func lockUI() {
        guard lock.engage() else { return }
        sheet = nil
        alert = nil
        confirmation = nil
        fileImport = nil
        for id in Array(addDialogs.keys) { closeAddDialog(id) }
        for window in NSApp.windows where window.canBecomeMain && window !== mainWindow {
            window.close()
        }
    }

    /// Whether the main window is open and not minimized or hidden with the
    /// app (qBittorrent's `!isHidden()`); being covered by other windows still
    /// counts as shown, unlike `isMainWindowVisible`, which gates refreshing.
    var isMainWindowShown: Bool {
        guard let window = mainWindow else { return false }
        return window.isVisible && !window.isMiniaturized
    }

    func clearLockPassword() {
        lock.clearPassword()
    }

    /// Brings the unlock prompt forward (menu bar item).
    func showUnlockPrompt() {
        openWindow?(id: AppWindowID.main.rawValue)
        NSApp.activate()
    }

    /// Called after a successful unlock.
    func didUnlock() {
        refreshSoon()
    }
}
