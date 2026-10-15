import AppKit
import SwiftUI

/// "Software Used" tab: build information from the core and a
/// "Copy to clipboard" button.
struct AboutSoftwareTab: View {
    let info: BuildInfo?

    var body: some View {
        Form {
            Section("qBittorrent Neo was built with the following components:") {
                ForEach(rows, id: \.label) { row in
                    LabeledContent(row.label, value: row.value)
                }
            }
            Section {
                HStack {
                    Spacer()
                    Button("Copy to clipboard", systemImage: Symbol.docOnDoc, action: copy)
                        .disabled(info == nil)
                }
            }
        }
        .formStyle(.grouped)
        .textSelection(.enabled)
    }

    private var rows: [(label: String, value: String)] {
        guard let info else { return [] }
        return [
            (String(localized: "Version:"), info.app),
            (String(localized: "Compatible with qBittorrent:"), info.qbittorrentCompat),
            (String(localized: "WebAPI:"), info.webapi),
            (String(localized: "Engine:"), info.engine),
            (String(localized: "Qt:"), info.rustc),
            (String(localized: "Platform:"), "\(info.platform) (\(info.bitness)-bit)"),
            (String(localized: "macOS:"), ProcessInfo.processInfo.operatingSystemVersionString),
        ]
    }

    private func copy() {
        let text = rows.map { "\($0.label) \($0.value)" }.joined(separator: "\n") + "\n"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
