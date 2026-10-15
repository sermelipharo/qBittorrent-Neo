import AppKit

/// Tools › On Downloads Done (features.md §1.3.4, §4.10.5): on
/// `AllTorrentsFinished`, confirms with a 15-second countdown (skipped for
/// Exit when "Confirmation on auto-exit" is off), then quits; system
/// actions are one-shot and run while the app terminates.
@MainActor
final class CompletionActionController {
    /// Set while quitting because of a completion action (no exit prompt).
    private(set) static var isAutoExiting = false

    private let app: AppModel
    private var task: Task<Void, Never>?
    private var pendingSystemAction: CompletionAction?
    private var observer: (any NSObjectProtocol)?

    init(app: AppModel) {
        self.app = app
    }

    func start() {
        task = Task { [weak self] in
            guard let events = self?.app.events() else { return }
            for await event in events {
                if case .allTorrentsFinished = event { self?.allTorrentsFinished() }
            }
        }
        observer = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { self.performPendingSystemAction() }
        }
    }

    private func allTorrentsFinished() {
        let action = app.gui.completionAction
        guard action != .doNothing else { return }
        if action == .exitApp, !app.gui.confirmAutoExit {
            quit(for: action)
            return
        }
        let result = CompletionCountdownAlert(action: action).run()
        guard result.accepted else { return }
        if action == .exitApp, result.dontShowAgain { app.gui.confirmAutoExit = false }
        quit(for: action)
    }

    private func quit(for action: CompletionAction) {
        if action != .exitApp {
            pendingSystemAction = action
            app.gui.completionAction = .doNothing
        }
        Self.isAutoExiting = true
        NSApp.terminate(nil)
    }

    private func performPendingSystemAction() {
        guard let action = pendingSystemAction else { return }
        pendingSystemAction = nil
        SystemPowerAction.perform(action)
    }
}
