import SwiftUI

/// Icon of a feed tree row: inbox, folder, loading spinner, error, or the
/// feed's downloaded favicon (falling back to the RSS symbol).
struct RSSNodeIcon: View {
    let node: RSSNode

    var body: some View {
        if node.kind == .feed, node.isLoading {
            ProgressView()
                .controlSize(.small)
                .accessibilityLabel("Loading")
        } else if node.kind == .feed, node.hasError {
            Image(systemName: Symbol.exclamationmarkTriangleFill)
                .foregroundStyle(.orange)
                .accessibilityLabel("Error")
        } else if node.kind == .feed, !node.iconPath.isEmpty, let image = NSImage(contentsOfFile: node.iconPath) {
            Image(nsImage: image)
                .resizable()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
        } else {
            Image(systemName: symbol)
                .foregroundStyle(node.kind == .feed ? Color.orange : Color.accentColor)
                .accessibilityHidden(true)
        }
    }

    private var symbol: String {
        switch node.kind {
        case .unread: Symbol.tray
        case .folder: Symbol.folder
        case .feed: Symbol.dotRadiowavesUpForward
        }
    }
}
