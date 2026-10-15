import SwiftUI

/// A peer speed or total, blank when zero and "hide zero values" applies.
struct PeerValueText: View {
    let value: Int64
    let hideZero: Bool
    var isSpeed = false

    var body: some View {
        Text(hideZero && value <= 0 ? "" : (isSpeed ? UnitFormatter.speed(value) : UnitFormatter.size(value)))
            .monospacedDigit()
    }
}
