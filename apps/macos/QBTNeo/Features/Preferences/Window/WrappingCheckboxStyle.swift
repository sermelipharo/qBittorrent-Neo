import SwiftUI

/// The checkbox style of the column forms with a title that wraps onto more
/// lines when it is longer than the controls column, instead of being cut off.
struct WrappingCheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            configuration.label
                .fixedSize(horizontal: false, vertical: true)
        }
        .toggleStyle(.checkbox)
    }
}
