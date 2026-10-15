import SwiftUI

/// A decimal number field with a stepper (share ratio limits, step 0.05).
struct DecimalSpinControl: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...9_999
    var step = 0.05
    var width = FeatureDesign.Width.spinField

    var body: some View {
        HStack(spacing: Design.Spacing.tight) {
            TextField(title, value: $value, format: .number.precision(.fractionLength(2)))
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: width)
                .onChange(of: value) { clamp() }
            Stepper(title, value: $value, in: range, step: step)
                .labelsHidden()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }

    private func clamp() {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        if clamped != value { value = clamped }
    }
}
