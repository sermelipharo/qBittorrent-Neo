import AppKit

/// The menu bar item's text drawn as a template image of a fixed width. The system lays out a menu bar title with
/// proportional glyphs, so a rate changing from "41M" to "44M" moved every item to its left by a point or two;
/// an image of the width of the widest text of the same length keeps the item still.
@MainActor
enum MenuBarTextImage {
    static let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

    /// The widest text with the same shape: digits as "0", letters as "M".
    static func widestForm(of text: String) -> String {
        String(text.map { $0.isNumber ? "0" : ($0.isLetter ? "M" : $0) })
    }

    static func width(of text: String) -> Double {
        ceil((widestForm(of: text) as NSString).size(withAttributes: [.font: font]).width)
    }

    static let gap = 4.0

    /// The optional symbol, a gap and the text, in one template image.
    static func make(_ text: String, symbol: String?) -> NSImage {
        let icon = symbol.flatMap { NSImage(systemSymbolName: $0, accessibilityDescription: nil) }?
            .withSymbolConfiguration(.init(pointSize: NSFont.systemFontSize, weight: .regular))
        let iconWidth = icon.map { ceil($0.size.width) + gap } ?? 0
        let height = max(ceil(font.ascender - font.descender), ceil(icon?.size.height ?? 0))
        let size = NSSize(width: iconWidth + width(of: text), height: height)
        let image = NSImage(size: size, flipped: false) { rect in
            if let icon {
                icon.draw(in: NSRect(x: 0, y: (rect.height - icon.size.height) / 2, width: icon.size.width, height: icon.size.height))
            }
            (text as NSString).draw(
                at: NSPoint(x: iconWidth, y: (rect.height - (font.ascender - font.descender)) / 2 - font.descender),
                withAttributes: [.font: font, .foregroundColor: NSColor.black]
            )
            return true
        }
        image.isTemplate = true
        // The status button reads its label from the image (VoiceOver).
        image.accessibilityDescription = text
        return image
    }
}
