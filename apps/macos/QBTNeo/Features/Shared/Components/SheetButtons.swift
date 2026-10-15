import SwiftUI

/// Cancel + confirm buttons at the bottom of a sheet.
struct SheetButtons: View {
    var confirmTitle: LocalizedStringKey = "OK"
    var isConfirmDisabled = false
    let confirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }
                .keyboardShortcut(.cancelAction)
            Button(confirmTitle, action: confirm)
                .keyboardShortcut(.defaultAction)
                .disabled(isConfirmDisabled)
        }
        .padding(Design.Spacing.large)
    }
}
