import AppKit
import SwiftUI

/// Captures the real Settings window (toolbar panes, search field, pane
/// height) in light and dark appearance for every pane and a few states.
@MainActor
struct SettingsWindowSnapshots {
    let directory: URL
    let isWanted: (String) -> Bool

    private struct State {
        let name: String
        var pane: SettingsPane
        var segment = TransfersSegment.adding
        var showsAdvanced = false
        var query = ""
    }

    private var states: [State] {
        SettingsPane.allCases.map { State(name: "settings-\($0.rawValue)", pane: $0) } + [
            State(name: "settings-transfers-files", pane: .transfers, segment: .files),
            State(name: "settings-transfers-seeding", pane: .transfers, segment: .seedingQueue),
            State(name: "settings-transfers-searchrss", pane: .transfers, segment: .searchRSS),
            State(name: "settings-privacy-advanced", pane: .privacy, showsAdvanced: true),
            State(name: "settings-network-advanced", pane: .network, showsAdvanced: true),
            State(name: "settings-general-advanced", pane: .general, showsAdvanced: true),
            State(name: "settings-advanced-on", pane: .advanced, showsAdvanced: true),
            State(name: "settings-search-query", pane: .general,
                  query: ProcessInfo.processInfo.environment["QBT_SETTINGS_QUERY"] ?? "vpn"),
        ]
    }

    func run(model: AppModel) async {
        let wanted = states.filter { isWanted($0.name) }
        guard !wanted.isEmpty else { return }
        if model.client == nil {
            model.attach(DemoClient(large: false, animated: false))
            await model.refresh()
        }
        guard let window = await openSettingsWindow() else {
            print("snapshot: the Settings window did not open")
            return
        }
        let navigator = SettingsSnapshot.navigator
        for state in wanted {
            navigator.pane = state.pane
            navigator.segment = state.segment
            navigator.showsAdvanced = state.showsAdvanced
            navigator.query = state.query
            for (suffix, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                // The scene's content follows the app's appearance (this snapshot process only).
                NSApp.appearance = NSAppearance(named: appearance)
                window.appearance = NSApp.appearance
                try? await Task.sleep(for: .milliseconds(900))
                Self.write(window, to: directory.appending(path: "\(state.name)-\(suffix).png"))
            }
        }
        navigator.query = ""
        window.orderOut(nil)
        window.close()
    }

    /// Opens the Settings scene from a transparent helper window and waits for it.
    private func openSettingsWindow() async -> NSWindow? {
        let opener = NSWindow(contentViewController: NSHostingController(rootView: SettingsOpener()))
        opener.alphaValue = 0
        opener.isReleasedWhenClosed = false
        opener.orderFrontRegardless()
        defer {
            opener.orderOut(nil)
            opener.close()
        }
        for _ in 0..<40 {
            if let window = SettingsSnapshot.window { return window }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return SettingsSnapshot.window
    }

    static func write(_ window: NSWindow, to url: URL) {
        guard let frameView = window.contentView?.superview else { return }
        frameView.layoutSubtreeIfNeeded()
        guard let rep = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) else { return }
        frameView.cacheDisplay(in: frameView.bounds, to: rep)
        // The window background (a material) isn't part of the cached views:
        // composite the capture over the appearance's window background color.
        guard let image = rep.cgImage, let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
        var background = CGColor(gray: 1, alpha: 1)
        (window.appearance ?? NSApp.effectiveAppearance).performAsCurrentDrawingAppearance {
            background = NSColor.windowBackgroundColor.usingColorSpace(.sRGB)?.cgColor ?? background
        }
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        context.setFillColor(background)
        context.fill(bounds)
        context.draw(image, in: bounds)
        guard let composed = context.makeImage() else { return }
        try? NSBitmapImageRep(cgImage: composed).representation(using: .png, properties: [:])?.write(to: url)
        print("snapshot: \(url.lastPathComponent) \(Int(window.frame.width))x\(Int(window.frame.height))")
    }
}
