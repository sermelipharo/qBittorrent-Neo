import SwiftUI

/// A checkbox enabling a numeric limit ("-1 = unlimited" when unchecked).
struct LimitRow: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    @Binding var value: Int64
    var range: ClosedRange<Int64>
    var unit: String?

    var body: some View {
        LabeledContent {
            SpinControl(title: title, value: $value, range: range, unit: unit, width: FeatureDesign.Width.wideSpinField)
                .disabled(!isOn)
        } label: {
            Toggle(title, isOn: $isOn)
        }
    }
}
