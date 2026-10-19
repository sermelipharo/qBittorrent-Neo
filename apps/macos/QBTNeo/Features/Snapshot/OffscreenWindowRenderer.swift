import AppKit
import SwiftUI

/// Renders a SwiftUI view inside a real (transparent, never activated)
/// window, including the title bar and toolbar, and writes it to a PNG in
/// light and dark appearance. Real windows are needed because `Table`,
/// `Form` controls and toolbars are AppKit-backed and `ImageRenderer`
/// can't draw them.
@MainActor
struct OffscreenWindowRenderer {
    let directory: URL

    /// - Parameters:
    ///   - name: file name stem (`<name>-light.png`, `<name>-dark.png`).
    ///   - settle: time for `.task` loads and layout before capturing.
    func render(
        _ name: String, title: String, size: CGSize, settle: Duration = .milliseconds(900), active: Bool = false,
        @ViewBuilder content: () -> some View
    ) async {
        let view = content()
        let active = active || LaunchOptions.current.snapshotActive
        for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            let controller = NSHostingController(
                rootView: view.frame(width: size.width, height: size.height).modifier(SnapshotKeyAppearance(isActive: active))
            )
            controller.sceneBridgingOptions = [.toolbars, .title]
            let window = active ? ActiveSnapshotWindow(contentViewController: controller) : NSWindow(contentViewController: controller)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.title = title
            if LaunchOptions.current.snapshotClear {
                window.backgroundColor = .clear
                window.isOpaque = false
            }
            window.appearance = NSAppearance(named: appearance)
            window.alphaValue = 0
            window.isReleasedWhenClosed = false
            window.setContentSize(size)
            window.orderFrontRegardless()
            window.makeKey()
            try? await Task.sleep(for: settle)
            write(window, to: directory.appending(path: "\(name)-\(suffix).png"))
            window.orderOut(nil)
            window.close()
        }
    }

    private func write(_ window: NSWindow, to url: URL) {
        guard let frameView = window.contentView?.superview else { return }
        frameView.layoutSubtreeIfNeeded()
        guard let rep = SnapshotBitmap.capture(frameView) else { return }
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }
}
