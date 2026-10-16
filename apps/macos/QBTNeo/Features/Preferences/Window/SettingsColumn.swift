import SwiftUI

/// Lays out one pane's column (header, form and footer): as wide as its
/// content wants, between `minWidth` and `maxWidth`, and centered in the
/// width it is offered. The margins to the left and right of the column are
/// therefore equal, and a long row wraps instead of running past the window.
struct SettingsColumn: Layout {
    let minWidth: Double
    let maxWidth: Double

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let content = subviews.first else { return .zero }
        let width = columnWidth(of: content, offered: proposal.width ?? maxWidth)
        let height = content.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let content = subviews.first else { return }
        let width = columnWidth(of: content, offered: bounds.width)
        // The content may take less than the offered width: center what it takes.
        let size = content.sizeThatFits(ProposedViewSize(width: width, height: nil))
        content.place(
            at: CGPoint(x: bounds.midX - size.width / 2, y: bounds.minY), anchor: .topLeading,
            proposal: ProposedViewSize(width: size.width, height: size.height)
        )
    }

    private func columnWidth(of content: LayoutSubview, offered: Double) -> Double {
        let ideal = content.sizeThatFits(.unspecified).width
        return min(max(ideal, minWidth), maxWidth, offered).rounded(.down)
    }
}
