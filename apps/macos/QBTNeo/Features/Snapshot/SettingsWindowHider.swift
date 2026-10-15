import AppKit
import SwiftUI

/// Snapshot mode only: makes the Settings window transparent as soon as its
/// content is attached (before the window is first drawn) and records it for capture.
struct SettingsWindowHider: NSViewRepresentable {
    func makeNSView(context: Context) -> HiderView {
        HiderView()
    }

    func updateNSView(_ nsView: HiderView, context: Context) {}

    final class HiderView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            window.alphaValue = 0
            // Don't record the snapshot window's frame in the user's defaults.
            window.setFrameAutosaveName("")
            window.isRestorable = false
            MainActor.assumeIsolated { SettingsSnapshot.window = window }
        }
    }
}
