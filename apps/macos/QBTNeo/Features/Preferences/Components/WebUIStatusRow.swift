import AppKit
import SwiftUI

/// The WebUI server state: start-up error (red, like qBittorrent's "WebUI
/// configuration failed" label), the live URL with Copy and Open buttons, and
/// the temporary password generated when none is set.
struct WebUIStatusRow: View {
    let status: WebUiStatus?
    let isEnabled: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        if let status, isEnabled {
            if !status.error.isEmpty {
                InlineMessage(text: String(localized: "WebUI configuration failed. Reason: \(status.error)"))
            } else if status.running, let url = URL(string: status.url) {
                LabeledContent("Running at:") {
                    HStack(spacing: Design.Spacing.small) {
                        Text(status.url)
                            .monospaced()
                            .textSelection(.enabled)
                        Button("Copy", systemImage: Symbol.docOnDoc) { copy(status.url) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .help("Copy")
                        Button("Open in Browser", systemImage: Symbol.safari) { openURL(url) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .help("Open in Browser")
                    }
                }
            }
            if !status.temporaryPassword.isEmpty {
                LabeledContent("Temporary password:") {
                    Text(status.temporaryPassword)
                        .monospaced()
                        .textSelection(.enabled)
                }
                .help("The WebUI administrator password was not set. A temporary password is provided for this session.")
            }
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
