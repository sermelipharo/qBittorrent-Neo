import AppKit

/// qBittorrent's `ShutdownConfirmDialog`: a floating warning alert that
/// counts down 15 seconds and accepts at zero; Cancel is the default.
/// AppKit is used because it must appear even when no window is open.
@MainActor
struct CompletionCountdownAlert {
    let action: CompletionAction
    static let seconds = 15

    struct Result {
        let accepted: Bool
        let dontShowAgain: Bool
    }

    func run() -> Result {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = title
        alert.addButton(withTitle: String(localized: "Cancel"))
        alert.addButton(withTitle: confirmTitle)
        if action == .exitApp {
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = String(localized: "Don't show again")
        }
        alert.informativeText = text(Self.seconds)
        alert.window.level = .floating
        NSApp.activate()
        let countdown = Countdown(alert: alert, remaining: Self.seconds, format: text)
        let timer = Timer(timeInterval: 1, repeats: true) { _ in
            MainActor.assumeIsolated { countdown.tick() }
        }
        RunLoop.main.add(timer, forMode: .modalPanel)
        let response = alert.runModal()
        timer.invalidate()
        return Result(accepted: response == .alertSecondButtonReturn, dontShowAgain: alert.suppressionButton?.state == .on)
    }

    private func text(_ seconds: Int) -> String {
        message + "\n" + String(localized: "You can cancel the action within \(seconds) seconds.")
    }

    private var title: String {
        switch action {
        case .exitApp: String(localized: "Exit confirmation")
        case .shutdown: String(localized: "Shutdown confirmation")
        case .suspend: String(localized: "Suspend confirmation")
        case .reboot: String(localized: "Reboot confirmation")
        case .doNothing: ""
        }
    }

    private var message: String {
        switch action {
        case .exitApp: String(localized: "qBittorrent Neo will now exit.")
        case .shutdown: String(localized: "The computer is going to shutdown.")
        case .suspend: String(localized: "The computer is going to enter suspend mode.")
        case .reboot: String(localized: "The computer is going to reboot.")
        case .doNothing: ""
        }
    }

    private var confirmTitle: String {
        switch action {
        case .exitApp: String(localized: "Exit Now")
        case .shutdown: String(localized: "Shutdown Now")
        case .suspend: String(localized: "Suspend Now")
        case .reboot: String(localized: "Reboot Now")
        case .doNothing: ""
        }
    }
}
