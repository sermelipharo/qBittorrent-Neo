import AppKit
import SwiftUI

/// "RSS Feed Options" (features.md §3.24): URL and per-feed refresh
/// interval in seconds (0 = "Default", the global interval). The sheet
/// stays open with the entered values when the core rejects them.
struct RSSFeedSheet: View {
    @State private var url: String
    @State private var refreshInterval: Int64
    let confirm: (String, Int64) async -> Bool
    @Environment(\.dismiss) private var dismiss

    init(url: String, refreshInterval: Int64, confirm: @escaping (String, Int64) async -> Bool) {
        _url = State(initialValue: url)
        _refreshInterval = State(initialValue: refreshInterval)
        self.confirm = confirm
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("URL:", text: $url, prompt: Text("https://example.org/feed.xml"))
                SpinField(title: "Refresh interval:", value: $refreshInterval, range: 0...Int64(Int32.max),
                          step: 60, unit: String(localized: "sec"), special: .text(String(localized: "Default")),
                          width: FeatureDesign.Width.wideSpinField)
            }
            .formStyle(.grouped)
            SheetButtons(isConfirmDisabled: url.trimmingCharacters(in: .whitespaces).isEmpty, confirm: submit)
        }
        .frame(width: FeatureDesign.Window.sheetWidth)
        .fixedSize(horizontal: false, vertical: true)
        .navigationTitle("RSS Feed Options")
    }

    private func submit() {
        Task {
            if await confirm(url, refreshInterval) { dismiss() }
        }
    }

    /// Clipboard text when it is a URL with a network scheme, else `https://`.
    static func clipboardURL() -> String {
        let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lower = text.lowercased()
        return lower.hasPrefix("http://") || lower.hasPrefix("https://") ? text : "https://"
    }
}
