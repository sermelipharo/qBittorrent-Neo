import SwiftUI

/// Default / Yes / No picker for optional settings.
struct OptionalBoolPicker: View {
    let title: LocalizedStringKey
    @Binding var value: Bool?

    var body: some View {
        Picker(title, selection: $value) {
            Text("Default").tag(Bool?.none)
            Text("Yes").tag(Optional(true))
            Text("No").tag(Optional(false))
        }
    }
}
