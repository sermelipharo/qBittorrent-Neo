import SwiftUI

/// The WebUI server state: start-up error (red, like qBittorrent's
/// "WebUI configuration failed" label), the URL, and the temporary password
/// generated when none is set.
struct WebUIStatusRow: View {
    let status: WebUiStatus?
    let isEnabled: Bool

    var body: some View {
        if let status, isEnabled {
            if !status.error.isEmpty {
                InlineMessage(text: String(localized: "WebUI configuration failed. Reason: \(status.error)"))
            } else if status.running, let url = URL(string: status.url) {
                LabeledContent("Running at:") {
                    Link(status.url, destination: url)
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
}
