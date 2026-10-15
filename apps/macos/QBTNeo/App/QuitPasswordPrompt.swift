import AppKit

/// "UI lock password" question shown when quitting while the UI is locked and
/// the main window is hidden (qBittorrent's `unlockUI()` on Exit).
@MainActor
enum QuitPasswordPrompt {
    /// Returns the typed password, or nil when cancelled.
    static func ask() -> String? {
        let alert = NSAlert()
        alert.messageText = String(localized: "UI lock password")
        alert.informativeText = String(localized: "Please type the UI lock password:")
        alert.addButton(withTitle: String(localized: "OK"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return nil }
        return field.stringValue
    }

    static func showInvalid() {
        let alert = NSAlert()
        alert.messageText = String(localized: "Invalid password")
        alert.informativeText = String(localized: "The password is invalid")
        alert.alertStyle = .warning
        alert.runModal()
    }
}
