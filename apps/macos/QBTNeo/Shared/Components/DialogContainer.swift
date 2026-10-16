import SwiftUI

/// Standard sheet layout: title, content, and Cancel / confirm buttons
/// (Return confirms, Escape cancels).
struct DialogContainer<Content: View>: View {
    let title: LocalizedStringKey
    var confirmTitle: LocalizedStringKey = "OK"
    var confirmRole: ButtonRole?
    var isConfirmDisabled = false
    var width = Design.Window.dialogWidth
    /// Cancel is the default button (removal confirmation): Return cancels, and so does
    /// Escape; the confirm button has no key equivalent.
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
                    .keyboardShortcut(cancelIsDefault ? nil : .defaultAction)
                    .disabled(isConfirmDisabled)
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(width: width)
        .background {
            // With Cancel as the default button (Return), Escape must still cancel, never confirm.
            if cancelIsDefault {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        }
    }
}
