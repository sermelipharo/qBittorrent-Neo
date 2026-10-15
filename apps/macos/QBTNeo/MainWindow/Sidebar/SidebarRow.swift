import AppKit
import SwiftUI

/// A sidebar filter row: icon, title and count badge.
struct SidebarRow: View {
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
            } else {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }
        }
        .badge(count)
        .help(title)
    }
}
