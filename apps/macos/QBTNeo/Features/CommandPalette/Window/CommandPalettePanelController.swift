import AppKit
import SwiftUI

/// Shows the palette panel centered over the main window (upper half, like
/// Spotlight and Xcode's Open Quickly) on a behind-window material, and
/// closes it when it loses key status (a click outside, another window).
@MainActor
final class CommandPalettePanelController: NSObject, NSWindowDelegate {
    static let size = CGSize(width: 640, height: 440)
    static let cornerRadius = 16.0

    private let panel = CommandPalettePanel(size: size)
    private weak var model: CommandPaletteModel?
    private weak var parentWindow: NSWindow?

    init(model: CommandPaletteModel) {
        self.model = model
        super.init()
        let background = NSVisualEffectView(frame: CGRect(origin: .zero, size: Self.size))
        background.material = .popover
        background.blendingMode = .behindWindow
        background.state = .active
        background.maskImage = Self.roundedMask(radius: Self.cornerRadius)
        let hosting = NSHostingView(rootView: CommandPaletteView(model: model))
        hosting.frame = background.bounds
        hosting.autoresizingMask = [.width, .height]
        background.addSubview(hosting)
        panel.contentView = background
        panel.delegate = self
        panel.onCancel = { [weak model] in model?.cancel() }
        panel.onCommandDigit = { [weak model] in model?.run(number: $0) }
    }

    /// Centers the panel over `window` (or the active screen) and makes it key.
    func show(over window: NSWindow?) {
        let area = window?.frame ?? (NSScreen.main?.visibleFrame ?? .zero)
        var origin = CGPoint(x: area.midX - Self.size.width / 2,
                             y: area.maxY - area.height * 0.18 - Self.size.height)
        if let visible = (window?.screen ?? NSScreen.main)?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX), visible.maxX - Self.size.width)
            origin.y = min(max(origin.y, visible.minY), visible.maxY - Self.size.height)
        }
        panel.setFrameOrigin(origin)
        if let window, panel.parent !== window {
            window.addChildWindow(panel, ordered: .above)
        }
        parentWindow = window
        panel.makeKeyAndOrderFront(nil)
        panel.invalidateShadow()
        #if DEBUG
        // Scripted UI runs keep the app inactive; the panel must still be shown (their timer hides it).
        if ProcessInfo.processInfo.environment["QBT_UI_SCRIPT"] != nil { panel.hidesOnDeactivate = false }
        #endif
    }

    func hide() {
        let wasKey = panel.isKeyWindow
        parentWindow?.removeChildWindow(panel)
        panel.orderOut(nil)
        if wasKey, let parentWindow, parentWindow.isVisible { parentWindow.makeKey() }
        parentWindow = nil
    }

    // MARK: NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        // Clicking outside, switching windows or apps closes the palette.
        model?.close()
    }

    // MARK: Shape

    private static func roundedMask(radius: Double) -> NSImage {
        let edge = radius * 2 + 1
        let image = NSImage(size: CGSize(width: edge, height: edge), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}
