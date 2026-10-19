import AppKit

/// A snapshot window drawn as the active (key and main) window, with colored
/// window controls and the accent-tinted default button, although a
/// snapshot run never activates the app (it must not take focus from the
/// user's frontmost application). Snapshot mode only.
final class ActiveSnapshotWindow: SnapshotWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    override var isKeyWindow: Bool { true }
    override var isMainWindow: Bool { true }

    /// AppKit's own check for drawing the active appearance (title bar
    /// buttons, default button), which otherwise also requires an active app.
    @objc(_hasActiveAppearance) var hasActiveAppearanceOverride: Bool { true }
    @objc(_hasActiveAppearanceIgnoringKeyFocus) var hasActiveAppearanceIgnoringKeyFocusOverride: Bool { true }
    @objc(_hasKeyAppearance) var hasKeyAppearanceOverride: Bool { true }
    @objc(_hasMainAppearance) var hasMainAppearanceOverride: Bool { true }
}
