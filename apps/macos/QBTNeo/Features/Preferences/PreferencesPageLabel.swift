import SwiftUI

/// Sidebar row: a white filled symbol on a tinted rounded square, like System Settings
/// (20 pt tile, ~5 pt corner radius, glyph about 60% of the tile).
struct PreferencesPageLabel: View {
    let page: PreferencesPage
    /// Secondary line (the matching settings in search results).
    var detail: String?

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 0) {
                Text(page.title)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        } icon: {
            Image(systemName: page.systemImage)
                .symbolVariant(.fill)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(page.tint.gradient, in: .rect(cornerRadius: 5))
        }
    }
}
