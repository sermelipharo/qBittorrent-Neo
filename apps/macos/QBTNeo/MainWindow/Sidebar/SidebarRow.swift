import AppKit
import SwiftUI

/// A sidebar filter row: icon, title and count badge.
struct SidebarRow: View {
    /// Fixed icon column so titles line up across rows and sections.
    private static let iconWidth: Double = 18

    @Environment(\.backgroundProminence) private var prominence

    let title: String
    let systemImage: String
    let count: Int
    var tint: Color = .secondary
    /// Replaces the symbol (tracker favicons).
    var image: NSImage?

    var body: some View {
        Label {
            Text(title)
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: TrackerFaviconStore.iconPoints, height: TrackerFaviconStore.iconPoints)
                    .frame(width: Self.iconWidth)
            } else {
                Image(systemName: systemImage)
                    .fontWeight(.medium)
                    // The selected row is filled with the accent color, so an accent-tinted symbol
                    // would vanish into it; draw it in the selection foreground instead.
                    .foregroundStyle(prominence == .increased ? AnyShapeStyle(.primary) : AnyShapeStyle(tint))
                    .frame(width: Self.iconWidth)
            }
        }
        .badge(count)
        .help(title)
    }
}
