#if DEBUG
import AppKit

/// Scenarios 2 and 3: quitting while the UI is locked and the window is hidden.
extension UIScenarios {
    static var password: String { ProcessInfo.processInfo.environment["QBT_UI_PW"] ?? "secret1" }

    /// Sets the lock password through the Lock command and its sheet, then locks (Cmd-L).
    static func lockThroughUI(_ d: UIDriver) async throws {
        await d.command("l")
        _ = await d.wait(timeout: 15) { sheetWindow(d) != nil }
        guard let sheet = sheetWindow(d) else { throw UIDriver.Failure(description: "lock password sheet did not open") }
        d.check(true, "Cmd-L opened the 'UI lock password' sheet")
        let field = try await d.require(role: "AXTextField", in: [sheet])
        await d.click(field)
        await d.type(password, window: sheet)
        await d.shot("lock-sheet")
        let ok = try await d.require(role: "AXButton", label: "OK", in: [sheet])
        await d.click(ok)
        let locked = await d.wait(timeout: 15) { d.model.lock.isLocked }
        d.check(locked, "UI is locked after saving the password")
        await d.pause(1.5)
        let unlock = d.find(role: "AXButton", label: "Unlock", in: [try mainWindow(d)])
        d.check(!unlock.isEmpty, "main window shows the lock screen (Unlock button)")
        await d.shot("lock-screen")
    }

    /// Hides the app with Cmd-H and checks that the main window no longer counts as shown.
    static func hideThroughUI(_ d: UIDriver) async throws {
        await d.command("h")
        let hidden = await d.wait(timeout: 10) { !d.model.isMainWindowShown }
        d.check(hidden, "after Cmd-H the main window is not shown (isHidden=\(NSApp.isHidden))")
    }

    /// Schedules answers to the "UI lock password" alert the next quit raises. The alert runs a modal loop
    /// in which Swift tasks are not serviced, so every step is a run-loop timer.
    static func scheduleQuitPromptAnswer(_ d: UIDriver, password: String, shotPrefix: String) {
        d.afterCommon(1.5) {
            guard let alert = NSApp.modalWindow else {
                d.log("FAIL: no modal quit prompt appeared")
                return
            }
            d.log("PASS: quit prompt shown: modal window '\(alert.title)' with \(d.find(role: "AXButton", in: [alert]).map(\.label))")
            for element in d.elements(in: alert) where element.role == "AXStaticText" { d.log("  alert text: \(element.value)") }
            UIDriver.setHidden(false)
            d.requestShotNow("\(shotPrefix)-prompt")
            if let field = d.views(in: alert, classNameContains: "SecureTextField").first {
                alert.makeFirstResponder(field)
            } else {
                d.log("FAIL: no secure field in the quit prompt")
            }
        }
        d.afterCommon(3.0) {
            UIDriver.setHidden(true)
            guard let alert = NSApp.modalWindow else { return }
            d.typeNow(password, window: alert)
        }
        d.afterCommon(4.0) {
            guard let alert = NSApp.modalWindow else { return }
            d.log("KEY Return in the quit prompt")
            d.keyNow("\r", code: 36, window: alert)
        }
        d.afterCommon(4.8) { clickOKIfStillShown(d, "the quit prompt") }
    }

    /// Return does not reach the default button of an alert of an inactive app; click OK when the alert is still up.
    static func clickOKIfStillShown(_ d: UIDriver, _ what: String) {
        guard let alert = NSApp.modalWindow, let ok = d.find(role: "AXButton", label: "OK", in: [alert]).first else { return }
        d.log("Return did not close \(what); clicking its OK button")
        d.clickNow(ok)
    }

    /// Answers the "Invalid password" alert that follows a wrong password.
    static func scheduleInvalidPasswordDismissal(_ d: UIDriver, shotPrefix: String) {
        d.afterCommon(6.5) {
            guard let alert = NSApp.modalWindow else {
                d.log("FAIL: no 'Invalid password' alert appeared")
                return
            }
            let texts = d.elements(in: alert).filter { $0.role == "AXStaticText" }.map(\.value)
            d.log("PASS: error alert shown after the wrong password: \(texts)")
            UIDriver.setHidden(false)
            d.requestShotNow("\(shotPrefix)-invalid")
        }
        d.afterCommon(8.5) {
            UIDriver.setHidden(true)
            guard let alert = NSApp.modalWindow else { return }
            d.log("KEY Return dismisses the error alert")
            d.keyNow("\r", code: 36, window: alert)
        }
        d.afterCommon(9.3) { clickOKIfStillShown(d, "the error alert") }
    }

    static func lockQuit(_ d: UIDriver) async throws {
        try await waitRunning(d)
        try await addTorrentsThroughDialogs(d, paths: Array(torrentPaths.prefix(1)))
        await d.pause(2)
        try await lockThroughUI(d)
        try await hideThroughUI(d)

        d.log("--- quit with a WRONG password")
        scheduleQuitPromptAnswer(d, password: "not-the-password", shotPrefix: "lockquit-wrong")
        scheduleInvalidPasswordDismissal(d, shotPrefix: "lockquit-wrong")
        await d.command("q")
        await d.pause(14)
        d.check(NSApp.modalWindow == nil, "no modal alert left after the wrong password")
        d.check(d.model.lock.isLocked, "still locked and alive after the wrong password (quit was cancelled)")

        d.log("state after the cancelled quit: isHidden=\(NSApp.isHidden) mainWindowShown=\(d.model.isMainWindowShown)")
        if d.model.isMainWindowShown { try await hideThroughUI(d) }
        d.log("--- quit with the CORRECT password")
        scheduleQuitPromptAnswer(d, password: password, shotPrefix: "lockquit-right")
        await d.command("q")
        await d.pause(30)
        d.log("FAIL: process still alive 30 s after the correct password")
    }

    /// Scenario 3: an external process sends quit Apple Events (optionally with a logout reason) to this app
    /// while it is locked and hidden. `QBT_UI_ARG` is `plain` (must prompt) or a logout reason (must not).
    static func lockAppleEvent(_ d: UIDriver) async throws {
        let mode = ProcessInfo.processInfo.environment["QBT_UI_ARG"] ?? "plain"
        try await waitRunning(d)
        if d.model.lock.isLocked {
            d.log("started locked (lock state persisted from the previous run)")
        } else {
            try await lockThroughUI(d)
        }
        try await hideThroughUI(d)

        let prompted = Flag()
        let timer = Timer(timeInterval: 0.4, repeats: true) { _ in
            MainActor.assumeIsolated {
                guard let alert = NSApp.modalWindow, !prompted.value else { return }
                prompted.value = true
                let buttons = d.find(role: "AXButton", in: [alert]).map(\.label)
                if mode == "plain" {
                    d.log("PASS: plain quit event raised the password prompt (buttons \(buttons))")
                    UIDriver.setHidden(false)
                    d.requestShotNow("ae-plain-prompt")
                    d.afterCommon(1.5) {
                        UIDriver.setHidden(true)
                        if let cancel = d.find(role: "AXButton", label: "Cancel", in: [alert]).first { d.clickNow(cancel) }
                    }
                } else {
                    d.log("FAIL: quit event with reason \(mode) raised the password prompt")
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        RunLoop.main.add(timer, forMode: .modalPanel)

        let ready = ProcessInfo.processInfo.environment["QBT_UI_DIR", default: ""] + "/ready"
        FileManager.default.createFile(atPath: ready, contents: nil)
        d.log("READY for the external quit event (mode \(mode)); locked=\(d.model.lock.isLocked) windowShown=\(d.model.isMainWindowShown)")
        if mode == "plain" {
            _ = await d.wait(timeout: 60) { prompted.value }
            await d.pause(5)
            d.check(d.model.lock.isLocked, "after cancelling the prompt the app is alive and still locked")
            d.log("--- cleaning up: quit with the correct password")
            if d.model.isMainWindowShown { try await hideThroughUI(d) }
            scheduleQuitPromptAnswer(d, password: password, shotPrefix: "ae-cleanup")
            await d.command("q")
            await d.pause(30)
        } else {
            await d.pause(60)
        }
        d.log("FAIL: process still alive after the quit event / cleanup")
    }

    @MainActor final class Flag {
        var value = false
    }
}
#endif
