import SwiftUI

/// A number field with a stepper, unit and optional special text — the
/// SwiftUI counterpart of qBittorrent's spin boxes. The value is written on
/// Return or when the field loses focus; the stepper writes immediately.
struct SpinField: View {
    let title: LocalizedStringKey
    @Binding var value: Int64
    var range: ClosedRange<Int64>
    var step: Int64 = 1
    var unit: String?
    var special: SpinSpecial?
    var width = FeatureDesign.Width.spinField

    var body: some View {
        LabeledContent(title) {
            SpinControl(title: title, value: $value, range: range, step: step, unit: unit, special: special, width: width)
        }
    }
}
