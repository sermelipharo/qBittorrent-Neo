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
        _ name: String, title: String, size: CGSize, settle: Duration = .milliseconds(900),
        @ViewBuilder content: () -> some View
    ) async {
        let view = content()
        for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
            let controller = NSHostingController(rootView: view.frame(width: size.width, height: size.height))
            controller.sceneBridgingOptions = [.toolbars, .title]
            let window = NSWindow(contentViewController: controller)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.title = title
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
        guard let rep = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) else { return }
        frameView.cacheDisplay(in: frameView.bounds, to: rep)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }
}
