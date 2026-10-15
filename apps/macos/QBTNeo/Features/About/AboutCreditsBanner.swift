import SwiftUI

/// Heading of the "Based on qBittorrent" area: marks everything below it as
/// the work of the original authors, not of this application's author.
struct AboutCreditsBanner: View {
    let appName: String

    var body: some View {
        HStack(alignment: .top, spacing: Design.Spacing.medium) {
            Image(systemName: Symbol.person2)
                .font(.title)
                .foregroundStyle(.tint)
                .frame(width: 36)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                Text("Based on qBittorrent")
                    .font(.headline)
                Text("""
                \(appName) builds on the work of the qBittorrent project. The people below wrote and maintain \
                the original program; the credit for its design, behavior and texts is theirs.
                """)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
