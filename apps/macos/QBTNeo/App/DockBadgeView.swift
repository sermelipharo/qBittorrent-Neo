import AppKit

/// Draws the application icon with qBittorrent's speed badges: rounded
/// 128×30 pt badges, white bold 26 pt text, green download badge at the
/// bottom and the blue upload badge stacked above it.
final class DockBadgeView: NSView {
    var downloadText: String?
    var uploadText: String?

    private static let downloadColor = NSColor(hex: 0x377B2C, alpha: 0.9)
    private static let uploadColor = NSColor(hex: 0x183ED5, alpha: 0.9)

    override func draw(_ dirtyRect: NSRect) {
        NSApp.applicationIconImage?.draw(in: bounds)
        let scale = bounds.width / 128
        let badgeSize = NSSize(width: 128 * scale, height: 30 * scale)
        var y = 2 * scale
        if let downloadText {
            drawBadge(downloadText, color: Self.downloadColor, origin: NSPoint(x: 0, y: y), size: badgeSize, scale: scale)
            y += badgeSize.height + 2 * scale
        }
        if let uploadText {
            drawBadge(uploadText, color: Self.uploadColor, origin: NSPoint(x: 0, y: y), size: badgeSize, scale: scale)
        }
    }

    private func drawBadge(_ text: String, color: NSColor, origin: NSPoint, size: NSSize, scale: Double) {
        let rect = NSRect(origin: origin, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: 15 * scale, yRadius: 15 * scale)
        color.setFill()
        path.fill()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowOffset = NSSize(width: 0, height: -1)
        shadow.shadowBlurRadius = 2
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 26 * scale),
            .foregroundColor: NSColor.white,
            .shadow: shadow,
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let textSize = string.size()
        string.draw(at: NSPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2))
    }
}
