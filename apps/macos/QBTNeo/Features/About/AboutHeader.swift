import SwiftUI

/// App icon, name and version (`qBittorrent Neo v0.1.1 (64-bit)`).
struct AboutHeader: View {
    let version: String
    let bitness: Int32

    var body: some View {
        HStack(spacing: Design.Spacing.medium) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                Text("qBittorrent Neo")
                    .font(.title)
                    .bold()
                Text("\(version) (\(bitness)-bit)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .textSelection(.enabled)
            }
            Spacer()
        }
    }
}
