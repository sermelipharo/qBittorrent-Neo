import SwiftUI

/// An article title; unread ones use the link color and a filled dot.
struct RSSArticleRow: View {
    let item: RSSArticleItem
    let showsFeed: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Design.Spacing.regular) {
            Image(systemName: item.article.isRead ? Symbol.circle : Symbol.circleFill)
                .font(.caption)
                .foregroundStyle(item.article.isRead ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.tint))
                .accessibilityLabel(item.article.isRead ? "Read" : "Unread")
            VStack(alignment: .leading, spacing: Design.Spacing.hairline) {
                Text(item.article.title)
                    .foregroundStyle(item.article.isRead ? AnyShapeStyle(.secondary) : AnyShapeStyle(.link))
                    .lineLimit(2)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, Design.Spacing.hairline)
    }

    private var subtitle: String {
        let date = item.article.date > 0 ? ValueFormatter.date(item.article.date) : ""
        return showsFeed ? [item.feedTitle, date].filter { !$0.isEmpty }.joined(separator: " · ") : date
    }
}
