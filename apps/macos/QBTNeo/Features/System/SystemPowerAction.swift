import AppKit
import IOKit.pwr_mgt

/// Sleep, restart or shut down the Mac. Sleep uses IOKit; restart and
/// shut down ask System Events (Apple Events), which shows the system's
/// automation consent prompt the first time.
@MainActor
enum SystemPowerAction {
    static func perform(_ action: CompletionAction) {
        switch action {
        case .suspend:
            let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
            IOPMSleepSystem(port)
            IOServiceClose(port)
        case .shutdown:
            runSystemEvents("shut down")
        case .reboot:
            runSystemEvents("restart")
        case .exitApp, .doNothing:
            break
        }
    }

    private static func runSystemEvents(_ command: String) {
        var error: NSDictionary?
        NSAppleScript(source: "tell application \"System Events\" to \(command)")?.executeAndReturnError(&error)
    }
}
