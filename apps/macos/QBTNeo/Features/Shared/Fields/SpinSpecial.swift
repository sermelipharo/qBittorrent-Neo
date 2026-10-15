import Foundation

/// A sentinel value shown as text in a spin field ("∞", "Disabled",
/// "0 (system default)", …).
struct SpinSpecial: Hashable, Codable, Sendable {
    let value: Int64
    let text: String

    static func infinity(at value: Int64 = 0) -> Self { Self(value: value, text: "∞") }

    static func text(_ text: String, at value: Int64 = 0) -> Self { Self(value: value, text: text) }
}
