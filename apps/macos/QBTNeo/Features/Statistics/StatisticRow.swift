import SwiftUI

/// One label/value line of the Statistics window; values are selectable and
/// use monospaced digits so they don't jitter while updating.
struct StatisticRow: View {
    let title: LocalizedStringKey
    let value: String

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .monospacedDigit()
                .textSelection(.enabled)
        }
    }
}
