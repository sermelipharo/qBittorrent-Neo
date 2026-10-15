import SwiftUI

/// A command's key equivalent: applied to its menu item and shown on the
/// right of its Command Palette row.
struct CommandShortcut: Sendable {
    let key: KeyEquivalent
    let modifiers: EventModifiers

    init(_ key: KeyEquivalent, _ modifiers: EventModifiers = .command) {
        self.key = key
        self.modifiers = modifiers
    }

    var keyboardShortcut: KeyboardShortcut { KeyboardShortcut(key, modifiers: modifiers) }

    /// Symbols in the HIG order (Control, Option, Shift, Command), then the key: "⇧⌘O".
    var display: String {
        var text = ""
        if modifiers.contains(.control) { text += "⌃" }
        if modifiers.contains(.option) { text += "⌥" }
        if modifiers.contains(.shift) { text += "⇧" }
        if modifiers.contains(.command) { text += "⌘" }
        return text + Self.keyName(key)
    }

    /// Spoken form for VoiceOver ("Shift Command O").
    var accessibilityName: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append(String(localized: "Control")) }
        if modifiers.contains(.option) { parts.append(String(localized: "Option")) }
        if modifiers.contains(.shift) { parts.append(String(localized: "Shift")) }
        if modifiers.contains(.command) { parts.append(String(localized: "Command")) }
        parts.append(Self.keyName(key))
        return parts.joined(separator: " ")
    }

    private static func keyName(_ key: KeyEquivalent) -> String {
        switch key {
        case .delete: "⌫"
        case .deleteForward: "⌦"
        case .return: "↩"
        case .escape: "⎋"
        case .tab: "⇥"
        case .space: "␣"
        case .upArrow: "↑"
        case .downArrow: "↓"
        case .leftArrow: "←"
        case .rightArrow: "→"
        default: String(key.character).uppercased()
        }
    }
}
