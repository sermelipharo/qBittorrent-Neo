import SwiftUI

/// One share-limit line: the mode combo, then the value control (enabled
/// for "Set to") or the inherited value in grey (for "Default").
struct ShareLimitRow<ValueControl: View>: View {
    let title: LocalizedStringKey
    @Binding var mode: ParamsLimitMode
    let fromCategory: Bool
    let inherited: String
    @ViewBuilder let valueControl: ValueControl

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: Design.Spacing.small) {
                Picker(title, selection: $mode) {
                    ForEach(ParamsLimitMode.allCases, id: \.self) { mode in
                        Text(mode.title(fromCategory: fromCategory)).tag(mode)
                    }
                }
                .labelsHidden()
                .fixedSize()
                valueControl
                    .opacity(mode == .value ? 1 : 0)
                    .disabled(mode != .value)
                    .overlay(alignment: .leading) {
                        Text(inherited)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                            .opacity(mode == .inherit ? 1 : 0)
                            .allowsHitTesting(false)
                    }
            }
        }
    }
}
