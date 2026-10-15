import Foundation

/// Deterministic pseudo-random generator (SplitMix64) so demo data and
/// snapshots are identical between runs.
struct DemoRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    init(_ text: String) {
        state = Self.hash(text)
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        Int.random(in: range, using: &self)
    }

    mutating func pick<T>(_ values: [T]) -> T {
        values[Int(next() % UInt64(values.count))]
    }

    /// FNV-1a 64-bit.
    static func hash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x0000_0100_0000_01B3
        }
        return hash
    }

    /// A stable hex string of `length` characters derived from `text`.
    static func hex(_ text: String, length: Int) -> String {
        var generator = Self(text)
        var result = ""
        while result.count < length {
            result += String(generator.next(), radix: 16).leftPadded(to: 16)
        }
        return String(result.prefix(length))
    }

    /// Smooth noise in 0...1 for animating speeds over time.
    static func wave(_ time: Double, seed: UInt64) -> Double {
        let phase = Double(seed % 1000) / 1000 * .pi * 2
        let slow = sin(time / 23 + phase)
        let fast = sin(time / 5.3 + phase * 1.7) * 0.35
        return min(max(0.5 + 0.35 * slow + 0.15 * fast, 0), 1)
    }
}

private extension String {
    func leftPadded(to length: Int) -> String {
        count >= length ? self : String(repeating: "0", count: length - count) + self
    }
}
