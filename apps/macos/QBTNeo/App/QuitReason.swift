import AppKit

/// Why the current quit request arrived. System logout, restart and shutdown
/// must never be blocked by the UI lock or the exit confirmation.
enum QuitReason {
    /// True when the Apple event being handled is a quit caused by the system
    /// ending the session (log out, restart, shut down or their dialogs).
    @MainActor
    static var isSystemSessionEnd: Bool {
        guard let event = NSAppleEventManager.shared().currentAppleEvent,
              event.eventClass == AEEventClass(kCoreEventClass),
              event.eventID == AEEventID(kAEQuitApplication),
              let reason = event.attributeDescriptor(forKeyword: AEKeyword(kAEQuitReason))
                  ?? event.paramDescriptor(forKeyword: AEKeyword(kAEQuitReason))
        else { return false }
        return sessionEndReasons.contains(reason.enumCodeValue)
    }

    private static let sessionEndReasons: Set<OSType> = [
        OSType(kAEReallyLogOut), OSType(kAELogOut), OSType(kAERestart),
        OSType(kAEShowRestartDialog), OSType(kAEShutDown), OSType(kAEShowShutdownDialog),
    ]
}
