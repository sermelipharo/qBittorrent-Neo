import AppKit
import SwiftUI

/// Turns an article description into display text without loading anything
/// remote and without scripts (features.md §5.12.1 "renderArticle"): rich
/// HTML is sanitized (scripts, styles, frames, embeds and images removed,
/// relative links made absolute) and imported as attributed text; plain
/// text has its BBCode converted first. Colors and fonts follow the system.
@MainActor
enum RSSDescriptionRenderer {
    static func render(_ description: String, link: String) -> AttributedString {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return AttributedString() }
        let html = mightBeRichText(trimmed) ? trimmed : "<pre>\(bbCodeToHTML(escape(trimmed)))</pre>"
        let sanitized = absolutizeLinks(sanitize(html), base: link)
        let wrapped = "<html><head><meta charset=\"utf-8\"></head><body>\(sanitized)</body></html>"
        guard let data = wrapped.data(using: .utf8),
              let imported = try? NSMutableAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
              )
        else { return AttributedString(stripTags(trimmed)) }
        normalize(imported)
        let text = (try? AttributedString(imported, including: \.appKit)) ?? AttributedString(imported.string)
        return text
    }

    /// `Qt::mightBeRichText`: a tag near the start.
    static func mightBeRichText(_ text: String) -> Bool {
        text.range(of: #"<\s*/?\s*[a-zA-Z][a-zA-Z0-9]*[^>]*>"#, options: .regularExpression) != nil
    }

    private static func escape(_ text: String) -> String {
        text.replacing("&", with: "&amp;").replacing("<", with: "&lt;").replacing(">", with: "&gt;")
    }

    /// qBittorrent's BBCode subset (`[b] [i] [u] [s] [url=] [color=] [size=]`); `[img]` becomes a link.
    static func bbCodeToHTML(_ text: String) -> String {
        var result = text
        let rules: [(String, String)] = [
            (#"\[img\](.+?)\[/img\]"#, "<a href=\"$1\">$1</a>"),
            (#"\[url=(\"?)(.+?)\1\]"#, "<a href=\"$2\">"),
            (#"\[/url\]"#, "</a>"),
            (#"\[(/)?([bius])\]"#, "<$1$2>"),
            (#"\[color=(\"?)(.+?)\1\]"#, "<span style=\"color:$2\">"),
            (#"\[/color\]"#, "</span>"),
            (#"\[size=(\"?)(.+?)\d\1\]"#, "<span>"),
            (#"\[/size\]"#, "</span>"),
        ]
        for (pattern, template) in rules {
            result = result.replacingOccurrences(of: pattern, with: template, options: [.regularExpression, .caseInsensitive])
        }
        return result
    }

    /// Removes everything that could load remote content or run code
    /// (allowlist: the output is rebuilt from formatting tags only).
    static func sanitize(_ html: String) -> String {
        RSSHTMLSanitizer.sanitize(html)
    }

    /// Relative `href`s resolved against the article link's `scheme://host/`.
    static func absolutizeLinks(_ html: String, base link: String) -> String {
        guard let url = URL(string: link), let scheme = url.scheme, let host = url.host() else { return html }
        let port = url.port.map { ":\($0)" } ?? ""
        let base = "\(scheme)://\(host)\(port)/"
        return html.replacingOccurrences(
            of: #"(<a\s+[^>]*?href\s*=\s*["'])(?!https?:|ftp:|mailto:|#)/?([^"']*)(["'])"#, with: "$1\(base)$2$3",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    private static func stripTags(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    /// System fonts (keeping bold/italic/monospace traits) and no imported colors.
    private static func normalize(_ text: NSMutableAttributedString) {
        let range = NSRange(location: 0, length: text.length)
        text.removeAttribute(.foregroundColor, range: range)
        text.removeAttribute(.backgroundColor, range: range)
        let base = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        text.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let traits = (value as? NSFont)?.fontDescriptor.symbolicTraits ?? []
            var font = traits.contains(.monoSpace) ? NSFont.monospacedSystemFont(ofSize: base.pointSize, weight: .regular) : base
            if let size = (value as? NSFont)?.pointSize, size > 16 { font = NSFont.systemFont(ofSize: min(size, 22), weight: .semibold) }
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits.intersection([.bold, .italic]))
            text.addAttribute(.font, value: NSFont(descriptor: descriptor, size: font.pointSize) ?? font, range: subrange)
        }
        while text.string.hasSuffix("\n") { text.deleteCharacters(in: NSRange(location: text.length - 1, length: 1)) }
    }
}
