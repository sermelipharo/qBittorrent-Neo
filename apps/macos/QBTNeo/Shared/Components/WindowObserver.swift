import AppKit
import SwiftUI

/// Reports whether the hosting window is actually visible (not occluded,
/// minimized or closed), so refresh work can pause when nobody sees it.
struct WindowObserver: NSViewRepresentable {
    let onVisibilityChange: @MainActor (Bool) -> Void
    /// Receives the hosting window once it is known.
    var onWindow: (@MainActor (NSWindow) -> Void)?

    func makeNSView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.onVisibilityChange = onVisibilityChange
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ nsView: ObserverView, context: Context) {
        nsView.onVisibilityChange = onVisibilityChange
        nsView.onWindow = onWindow
    }

    /// Tracks occlusion of the window it is installed in.
    final class ObserverView: NSView {
        var onVisibilityChange: (@MainActor (Bool) -> Void)?
        var onWindow: (@MainActor (NSWindow) -> Void)?
        private var observers: [NSObjectProtocol] = []

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            for observer in observers { NotificationCenter.default.removeObserver(observer) }
            observers.removeAll()
            guard let window else {
                onVisibilityChange?(false)
                return
            }
            onWindow?(window)
            let names: [Notification.Name] = [
                NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                NSWindow.didDeminiaturizeNotification, NSWindow.willCloseNotification,
            ]
            for name in names {
                observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] note in
                    let closing = note.name == NSWindow.willCloseNotification
                    MainActor.assumeIsolated { self?.report(closing: closing) }
                })
            }
            report(closing: false)
        }

        private func report(closing: Bool) {
            guard let window else { return }
            let visible = !closing && window.occlusionState.contains(.visible) && !window.isMiniaturized
            onVisibilityChange?(visible)
        }
    }
}
