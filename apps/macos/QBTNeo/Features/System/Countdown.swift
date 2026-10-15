import AppKit

/// Ticks the confirmation alert's countdown; accepts it at zero.
@MainActor
final class Countdown {
    private let alert: NSAlert
    private var remaining: Int
    private let format: (Int) -> String

    init(alert: NSAlert, remaining: Int, format: @escaping (Int) -> String) {
        self.alert = alert
        self.remaining = remaining
        self.format = format
    }

    func tick() {
        guard remaining > 0 else { return }
        remaining -= 1
        alert.informativeText = format(remaining)
        if remaining == 0 { NSApp.stopModal(withCode: .alertSecondButtonReturn) }
    }
}
