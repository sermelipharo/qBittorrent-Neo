import AppKit
import SwiftUI

extension Color {
    /// A color that resolves to `light` in light appearances and `dark` in dark ones.
    init(light: UInt32, dark: UInt32) {
        let provider: @Sendable (NSAppearance) -> NSColor = { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua, .vibrantDark, .vibrantLight]) == .darkAqua
                || appearance.bestMatch(from: [.darkAqua, .aqua, .vibrantDark, .vibrantLight]) == .vibrantDark
            return NSColor(hex: isDark ? dark : light)
        }
        self.init(nsColor: NSColor(name: nil, dynamicProvider: provider))
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        self.init(
            srgbRed: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
