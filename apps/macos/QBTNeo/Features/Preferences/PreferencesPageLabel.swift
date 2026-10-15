import SwiftUI

/// Sidebar row: a white filled symbol on a tinted rounded square, like System Settings
/// (20 pt tile, 5 pt corner radius, glyph fitted into 60% of the tile).
struct PreferencesPageLabel: View {
    let page: PreferencesPage
    /// Secondary line (the matching settings in search results).
    var detail: String?

    private static let tile: CGFloat = 20
    private static let glyph: CGFloat = 12

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
            // A font size sets the glyph's em size, not its drawn bounds (wide and
            // filled symbols overflow it), so the glyph is fitted into a fixed box.
            Image(systemName: page.systemImage)
                .resizable()
                .symbolVariant(.fill)
                .scaledToFit()
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(width: Self.glyph, height: Self.glyph)
                .frame(width: Self.tile, height: Self.tile)
                .background(page.tint.gradient, in: .rect(cornerRadius: 5))
        }
    }
}
