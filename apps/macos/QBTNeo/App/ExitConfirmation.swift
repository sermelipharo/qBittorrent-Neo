import AppKit

/// "Exiting qBittorrent" question shown on quit while torrents transfer
/// (No is the default; Always Yes turns the confirmation off).
@MainActor
enum ExitConfirmation {
    enum Answer {
        case no, yes, always
    }

    static func ask() -> Answer {
        let alert = NSAlert()
        alert.messageText = String(localized: "Exiting qBittorrent Neo")
        alert.informativeText = String(localized: "Some files are currently transferring.\nAre you sure you want to quit qBittorrent Neo?")
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: "No"))
        alert.addButton(withTitle: String(localized: "Yes"))
        alert.addButton(withTitle: String(localized: "Always Yes"))
        switch alert.runModal() {
        case .alertSecondButtonReturn: return .yes
        case .alertThirdButtonReturn: return .always
        default: return .no
        }
    }
}
