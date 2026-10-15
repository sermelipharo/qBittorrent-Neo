import SwiftUI

/// The field + stepper + unit part of `SpinField`, usable without a label
/// (e.g. next to a checkbox).
struct SpinControl: View {
    let title: LocalizedStringKey
    @Binding var value: Int64
    var range: ClosedRange<Int64>
    var step: Int64 = 1
    var unit: String?
    var special: SpinSpecial?
    var width = FeatureDesign.Width.spinField

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Spacing.tight) {
            TextField(title, value: $value, format: SpinFormat(range: range, special: special, suffix: unit))
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: width)
            Stepper(title, value: $value, in: range, step: Int64.Stride(step))
                .labelsHidden()
            if let unit {
                Text(unit)
                    .foregroundStyle(.secondary)
                    .opacity(value == special?.value ? 0 : 1)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(value == special?.value ? special?.text ?? "" : "\(value) \(unit ?? "")")
    }
}
