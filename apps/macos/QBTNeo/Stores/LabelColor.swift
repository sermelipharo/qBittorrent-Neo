import AppKit
import SwiftUI

/// The color of a category or tag: a named system color or a custom sRGB one.
/// Stored as the system color's name (`"teal"`) or `#RRGGBB`.
enum LabelColor: Hashable, Sendable {
    case system(LabelTint)
    case custom(red: Int, green: Int, blue: Int)

    init?(storage: String) {
        if let tint = LabelTint(rawValue: storage) {
            self = .system(tint)
            return
        }
        guard storage.count == 7, storage.hasPrefix("#"), let value = Int(storage.dropFirst(), radix: 16) else { return nil }
        self = .custom(red: value >> 16 & 0xFF, green: value >> 8 & 0xFF, blue: value & 0xFF)
    }

    /// A custom color from any SwiftUI color (converted to sRGB, opacity dropped).
    init(_ color: Color) {
        let resolved = NSColor(color).usingColorSpace(.sRGB) ?? .gray
        func component(_ value: CGFloat) -> Int { Int((min(max(value, 0), 1) * 255).rounded()) }
        self = .custom(red: component(resolved.redComponent), green: component(resolved.greenComponent),
                       blue: component(resolved.blueComponent))
    }

    var storage: String {
        switch self {
        case .system(let tint): tint.rawValue
        case let .custom(red, green, blue): String(format: "#%02X%02X%02X", red, green, blue)
        }
    }

    var color: Color {
        switch self {
        case .system(let tint): tint.color
        case let .custom(red, green, blue): Color(.sRGB, red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
        }
    }

    var title: String {
        switch self {
        case .system(let tint): tint.title
        case .custom: String(localized: "Custom color \(storage)")
        }
    }
}
