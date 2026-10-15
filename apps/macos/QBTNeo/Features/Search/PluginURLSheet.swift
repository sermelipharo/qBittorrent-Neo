import AppKit
import SwiftUI

/// "New search engine plugin URL": must point to a `.py` file.
struct PluginURLSheet: View {
    let install: (String) -> Void
    @State private var url = Self.initialURL()
    @State private var error: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text("New search engine plugin URL")
                .font(.headline)
            TextField("URL:", text: $url)
                .onSubmit(submit)
            if let error {
                InlineMessage(text: error)
            }
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Install", action: submit)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(width: FeatureDesign.Window.sheetWidth)
    }

    private func submit() {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return dismiss() }
        guard trimmed.lowercased().hasSuffix(".py") else {
            error = String(localized: "The link doesn't seem to point to a search engine plugin.")
            return
        }
        install(trimmed)
        dismiss()
    }

    private static func initialURL() -> String {
        let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lower = text.lowercased()
        return (lower.hasPrefix("http://") || lower.hasPrefix("https://")) && lower.hasSuffix(".py") ? text : "http://"
    }
}
