import SwiftUI

/// "<name>  (<unread>)" with the folder/feed icon; feeds show a spinner
/// while loading and a warning icon on error.
struct RSSNodeRow: View {
    let node: RSSNode

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            Label {
                Text(node.name)
                    .lineLimit(1)
            } icon: {
                RSSNodeIcon(node: node)
            }
            Spacer(minLength: Design.Spacing.tight)
            Text(node.unreadCount > 0 ? node.unreadCount.formatted() : "")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("\(node.unreadCount) unread"))
        }
        .help(node.kind == .feed ? node.url : node.name)
    }
}
