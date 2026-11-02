import AppKit
import SwiftUI

/// Runs an action on a middle click (mouse button 3). Every other event
/// passes through to the views below, so it can overlay a button.
struct MiddleClickCatcher: NSViewRepresentable {
    let action: @MainActor () -> Void

    func makeNSView(context: Context) -> CatcherView {
        CatcherView(action: action)
    }

    func updateNSView(_ view: CatcherView, context: Context) {
        view.action = action
    }

    final class CatcherView: NSView {
        var action: @MainActor () -> Void

        init(action: @escaping @MainActor () -> Void) {
            self.action = action
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            nil
        }

        /// Only middle-button events land here; clicks and hovers go through.
        override func hitTest(_ point: NSPoint) -> NSView? {
            switch NSApp.currentEvent?.type {
            case .otherMouseDown, .otherMouseUp: super.hitTest(point)
            default: nil
            }
        }

        override func otherMouseDown(with event: NSEvent) {
            if event.buttonNumber != 2 { super.otherMouseDown(with: event) }
        }

        override func otherMouseUp(with event: NSEvent) {
            if event.buttonNumber == 2 {
                action()
            } else {
                super.otherMouseUp(with: event)
            }
        }
    }
}
