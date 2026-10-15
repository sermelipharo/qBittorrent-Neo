import SwiftUI

/// Add/remove buttons plus Revert and Save for the cookie table.
struct CookiesBottomBar: View {
    let model: CookiesModel

    var body: some View {
        HStack(spacing: Design.Spacing.regular) {
            ControlGroup {
                Button("Add Cookie", systemImage: "plus", action: model.add)
                Button("Remove Selected Cookies", systemImage: "minus", action: model.removeSelected)
                    .disabled(model.selection.isEmpty)
            }
            .labelStyle(.iconOnly)
            .fixedSize()
            if let message = model.errorMessage {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
            Spacer()
            Button("Revert", action: model.revert)
                .disabled(!model.hasChanges)
            Button("Save", action: model.save)
                .keyboardShortcut(.defaultAction)
                .disabled(!model.hasChanges)
        }
        .padding(Design.Spacing.medium)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}
