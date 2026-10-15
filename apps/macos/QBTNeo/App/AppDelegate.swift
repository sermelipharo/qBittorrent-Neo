import AppKit
import SwiftUI

/// AppKit integration SwiftUI has no equivalent for: termination with the
/// exit confirmation and core shutdown, the Dock menu, Finder "Open With",
/// the Dock badge, and snapshot mode.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()
    private var dockBadge: DockBadgeController?
    private var systemIntegration: SystemIntegration?
    private var isTerminating = false
    private var isAskingPassword = false
    #if DEBUG
    private var verifyTimer: Timer?
    #endif

    override init() {
        // Never restore or save AppKit window state. The main window is always
        // presented at launch; a run that ended with no window open (snapshot
        // mode, quitting after closing it) leaves a "zero windows" state behind
        // that AppKit would restore on every later launch, and SwiftUI then
        // never presents the main window. State is keyed by the code-signing
        // identifier, so it also survives rebuilds.
        UserDefaults.standard.register(defaults: ["ApplePersistenceIgnoreState": true])
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let directory = model.launch.snapshotDirectory {
            Task {
                await SnapshotRenderer(directory: directory, launch: model.launch).run()
                NSApp.terminate(nil)
            }
            return
        }
        model.gui.applyAppearance()
        #if DEBUG
        verifyTimer = DebugVerification.install(model: model)
        #endif
        dockBadge = DockBadgeController(model: model)
        systemIntegration = SystemIntegration(app: model)
        Task { await model.start() }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !isTerminating else { return .terminateLater }
        if model.launch.isSnapshot { return .terminateNow }
        // Quitting a locked app whose window is hidden needs the lock password
        // (qBittorrent's Exit); a visible window shows the lock screen already.
        // The system ending the session is never blocked.
        if model.lock.isLocked, !model.isMainWindowShown, !QuitReason.isSystemSessionEnd {
            guard !isAskingPassword else { return .terminateCancel }
            isAskingPassword = true
            Task {
                let allowed = await askQuitPassword()
                isAskingPassword = false
                if allowed {
                    finishTermination()
                } else {
                    NSApp.reply(toApplicationShouldTerminate: false)
                }
            }
            return .terminateLater
        }
        if model.gui.confirmOnExit, model.status.isTransferring, !CompletionActionController.isAutoExiting,
           !QuitReason.isSystemSessionEnd {
            switch ExitConfirmation.ask() {
            case .no:
                return .terminateCancel
            case .always:
                model.gui.confirmOnExit = false
            case .yes:
                break
            }
        }
        finishTermination()
        return .terminateLater
    }

    /// Asks for the lock password; unlocks on success like qBittorrent.
    private func askQuitPassword() async -> Bool {
        guard let password = QuitPasswordPrompt.ask() else { return false }
        if await model.lock.unlock(with: password) {
            model.didUnlock()
            return true
        }
        QuitPasswordPrompt.showInvalid()
        return false
    }

    private func finishTermination() {
        isTerminating = true
        model.stopRefreshing()
        let client = model.client
        Task {
            await AppModel.shutdown(client)
            NSApp.reply(toApplicationShouldTerminate: true)
        }
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        DockMenuBuilder(model: model).makeMenu()
    }
}
