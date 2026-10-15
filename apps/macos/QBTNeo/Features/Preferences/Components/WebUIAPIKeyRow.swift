import AppKit
import SwiftUI

/// "API Key": masked key with copy, generate/rotate and delete buttons.
/// Each change is confirmed and takes effect immediately.
struct WebUIAPIKeyRow: View {
    @Bindable var model: PreferencesModel
    @State private var pending: APIKeyAction?

    var body: some View {
        let key = model.draft.webui.webUiApiKey
        LabeledContent("API key:") {
            HStack(spacing: Design.Spacing.small) {
                Text(key.isEmpty ? String(localized: "Generate a key") : APIKeyGenerator.masked(key))
                    .monospaced(!key.isEmpty)
                    .foregroundStyle(key.isEmpty ? .tertiary : .primary)
                    .lineLimit(1)
                    .accessibilityLabel(key.isEmpty ? "No API key" : "API key set")
                ControlGroup {
                    Button("Copy API key", systemImage: Symbol.docOnDoc, action: copy)
                        .disabled(key.isEmpty)
                        .help("Copy API key")
                    Button(key.isEmpty ? "Generate API key" : "Rotate API key",
                           systemImage: key.isEmpty ? Symbol.key : Symbol.arrowTriangle2Circlepath) {
                        pending = key.isEmpty ? .generate : .rotate
                    }
                    .help(key.isEmpty ? "Generate API key" : "Rotate API key")
                    Button("Delete API key", systemImage: Symbol.trash) { pending = .delete }
                        .disabled(key.isEmpty)
                        .help("Delete API key")
                }
                .labelStyle(.iconOnly)
                .fixedSize()
            }
        }
        .alert(pending?.title ?? "", item: $pending) { action in
            Button("Yes", role: action == .delete ? .destructive : nil) { perform(action) }
            Button("No", role: .cancel) {}
        } message: { action in
            Text(action.message)
        }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(model.draft.webui.webUiApiKey, forType: .string)
    }

    private func perform(_ action: APIKeyAction) {
        Task {
            switch action {
            case .generate, .rotate: await model.rotateAPIKey()
            case .delete: await model.deleteAPIKey()
            }
        }
    }
}
