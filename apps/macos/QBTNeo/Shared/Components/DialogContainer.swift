import SwiftUI

/// Standard sheet layout: title, content, and Cancel / confirm buttons
/// (Return confirms, Escape cancels).
struct DialogContainer<Content: View>: View {
    let title: LocalizedStringKey
    var confirmTitle: LocalizedStringKey = "OK"
    var confirmRole: ButtonRole?
    var isConfirmDisabled = false
    var width = Design.Window.dialogWidth
    /// Cancel gets the initial focus (removal confirmation) instead of confirm.
    var cancelIsDefault = false
    let onConfirm: () -> Void
    @ContentBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text(title)
                .font(.headline)
            content
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(cancelIsDefault ? .defaultAction : .cancelAction)
                Button(confirmTitle, role: confirmRole, action: onConfirm)
                    .keyboardShortcut(cancelIsDefault ? .cancelAction : .defaultAction)
                    .disabled(isConfirmDisabled)
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(width: width)
    }
}
