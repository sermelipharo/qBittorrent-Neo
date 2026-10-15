import AppKit

/// Target object that runs a closure for an `NSMenuItem`.
@MainActor
final class ClosureMenuTarget: NSObject {
    private let action: @MainActor () -> Void

    init(action: @escaping @MainActor () -> Void) {
        self.action = action
    }

    @objc func invoke() {
        NSApp.activate()
        action()
    }
}
