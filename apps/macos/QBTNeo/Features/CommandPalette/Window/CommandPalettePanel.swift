import AppKit

/// The palette's borderless panel. It sits at the normal window level as a
/// child of the main window (never above other apps), can become key for
/// typing, hides when the app deactivates, and routes ⌘1…⌘9 and Escape.
final class CommandPalettePanel: NSPanel {
    var onCancel: (() -> Void)?
    var onCommandDigit: ((Int) -> Void)?

    init(size: CGSize) {
        super.init(contentRect: CGRect(origin: .zero, size: size), styleMask: [.borderless], backing: .buffered, defer: true)
        level = .normal
        isFloatingPanel = false
        hidesOnDeactivate = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovable = false
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow
        collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        title = String(localized: "palette.title", defaultValue: "Command Palette", comment: "Command Palette window and menu item")
        setAccessibilitySubrole(.dialog)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers == .command, let character = event.charactersIgnoringModifiers, let digit = Int(character), (1 ... 9).contains(digit) {
            onCommandDigit?(digit)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
