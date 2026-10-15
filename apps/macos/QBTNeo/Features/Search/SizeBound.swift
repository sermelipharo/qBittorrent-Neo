import SwiftUI

/// A size value (0 = "∞" for the maximum) with its unit picker.
struct SizeBound: View {
    @Binding var value: Double
    @Binding var unit: SearchSizeUnit
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: Design.Spacing.hairline) {
            TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)), prompt: Text("∞"))
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .frame(width: FeatureDesign.Width.narrowField)
            Picker(title, selection: $unit) {
                ForEach(SearchSizeUnit.allCases) { unit in
                    Text(unit.title).tag(unit)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
    }
}
