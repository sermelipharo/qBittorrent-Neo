import Foundation

/// Allowlist sanitizer for untrusted article HTML. The output is rebuilt
/// from scratch: only a fixed set of formatting tags survives, with no
/// attributes except an `href` on links, so nothing in it can load remote
/// content (images, styles, frames) or run code when the HTML importer
/// renders it. Text and attribute values are re-escaped; the contents of
/// script-like elements are dropped entirely.
enum RSSHTMLSanitizer {
    /// Formatting tags kept (without attributes).
    static let allowedTags: Set<String> = [
        "a", "b", "strong", "i", "em", "u", "s", "strike", "del", "ins", "sub", "sup", "small", "big",
        "p", "br", "hr", "div", "span", "pre", "code", "tt", "kbd", "samp", "blockquote", "q", "cite",
        "ul", "ol", "li", "dl", "dt", "dd", "h1", "h2", "h3", "h4", "h5", "h6",
        "table", "thead", "tbody", "tfoot", "tr", "th", "td", "caption", "center", "font", "abbr",
    ]

    /// Elements whose content is not text and is removed with them.
    static let droppedContentTags: Set<String> = [
        "script", "style", "iframe", "object", "embed", "video", "audio", "svg", "math", "form",
        "frameset", "noscript", "template", "textarea", "select", "head", "title", "noembed", "noframes",
    ]

    /// Link schemes kept in `href`; anything else (javascript:, data:, file:,
    /// custom app schemes) is dropped. Relative links have no scheme.
    static let allowedSchemes: Set<String> = ["http", "https", "ftp", "mailto"]

    static func sanitize(_ html: String) -> String {
        let chars = Array(html.unicodeScalars)
        var out = String.UnicodeScalarView()
        var index = 0
        while index < chars.count {
            guard chars[index] == "<" else {
                appendEscaped(chars[index], to: &out)
                index += 1
                continue
            }
            // Comments, doctypes, CDATA and processing instructions vanish.
            if let next = chars[safe: index + 1], next == "!" || next == "?" {
                index = skipMarkup(chars, from: index)
                continue
            }
            guard let tag = parseTag(chars, from: index) else {
                appendEscaped("<", to: &out)
                index += 1
                continue
            }
            index = tag.end
            if droppedContentTags.contains(tag.name) {
                if !tag.closing && !tag.selfClosing {
                    index = skipElementContent(chars, from: index, name: tag.name)
                }
                continue
            }
            guard allowedTags.contains(tag.name) else { continue }
            out.append(contentsOf: rebuild(tag).unicodeScalars)
        }
        return String(out)
    }

    struct Tag {
        var name: String
        var closing: Bool
        var selfClosing: Bool
        var href: String?
        var end: Int
    }

    /// Parses `<name attr=value ...>` like an HTML tokenizer (attributes may
    /// be separated by whitespace or `/`). `nil` when `<` does not start a tag.
    static func parseTag(_ chars: [Unicode.Scalar], from start: Int) -> Tag? {
        var index = start + 1
        var closing = false
        if chars[safe: index] == "/" {
            closing = true
            index += 1
        }
        guard let first = chars[safe: index], isASCIILetter(first) else { return nil }
        var name = ""
        while let char = chars[safe: index], isASCIILetter(char) || ("0"..."9").contains(char) {
            name.unicodeScalars.append(char)
            index += 1
        }
        var tag = Tag(name: name.lowercased(), closing: closing, selfClosing: false, href: nil, end: index)
        while let char = chars[safe: index] {
            if char == ">" {
                tag.end = index + 1
                return tag
            }
            if isSpace(char) || char == "/" {
                tag.selfClosing = char == "/"
                index += 1
                continue
            }
            let (attrName, value, next) = parseAttribute(chars, from: index)
            if attrName == "href", tag.href == nil { tag.href = value }
            tag.selfClosing = false
            index = max(next, index + 1)
        }
        // Unterminated tag: treat as text.
        return nil
    }

    private static func parseAttribute(_ chars: [Unicode.Scalar], from start: Int) -> (String, String, Int) {
        var index = start
        var name = ""
        while let char = chars[safe: index], !isSpace(char), char != "/", char != ">", char != "=" {
            name.unicodeScalars.append(char)
            index += 1
        }
        while let char = chars[safe: index], isSpace(char) { index += 1 }
        guard chars[safe: index] == "=" else { return (name.lowercased(), "", index) }
        index += 1
        while let char = chars[safe: index], isSpace(char) { index += 1 }
        var value = String.UnicodeScalarView()
        if let quote = chars[safe: index], quote == "\"" || quote == "'" {
            index += 1
            while let char = chars[safe: index], char != quote {
                value.append(char)
                index += 1
            }
            index += 1
        } else {
            while let char = chars[safe: index], !isSpace(char), char != ">" {
                value.append(char)
                index += 1
            }
        }
        return (name.lowercased(), decodeEntities(String(value)), index)
    }

    private static func rebuild(_ tag: Tag) -> String {
        if tag.closing { return "</\(tag.name)>" }
        if tag.name == "a", let href = tag.href.flatMap(safeHref) {
            return "<a href=\"\(escapeAttribute(href))\">"
        }
        return "<\(tag.name)>"
    }

    /// The link target if its scheme is allowed (or it is relative).
    static func safeHref(_ raw: String) -> String? {
        // Browsers ignore control characters and whitespace inside schemes.
        let cleaned = String(String.UnicodeScalarView(raw.unicodeScalars.filter { $0.value > 0x20 && $0.value != 0x7F }))
        guard !cleaned.isEmpty else { return nil }
        if let colon = cleaned.firstIndex(of: ":") {
            let scheme = cleaned[..<colon]
            let looksLikeScheme = !scheme.isEmpty && !scheme.contains(where: { "/?#".contains($0) })
            if looksLikeScheme {
                return allowedSchemes.contains(scheme.lowercased()) ? cleaned : nil
            }
        }
        return cleaned
    }

    private static func skipMarkup(_ chars: [Unicode.Scalar], from start: Int) -> Int {
        let isComment = chars[safe: start + 2] == "-" && chars[safe: start + 3] == "-"
        var index = start + 2
        while index < chars.count {
            if isComment {
                if chars[index] == "-", chars[safe: index + 1] == "-", chars[safe: index + 2] == ">" { return index + 3 }
            } else if chars[index] == ">" {
                return index + 1
            }
            index += 1
        }
        return chars.count
    }

    /// Skips to just after `</name ...>` (case-insensitive) or to the end.
    private static func skipElementContent(_ chars: [Unicode.Scalar], from start: Int, name: String) -> Int {
        var index = start
        while index < chars.count {
            if chars[index] == "<", chars[safe: index + 1] == "/", let tag = parseTag(chars, from: index), tag.name == name {
                return tag.end
            }
            index += 1
        }
        return chars.count
    }

    private static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return text }
        // Enough decoding for scheme detection (`jav&#x61;script:`,
        // `javascript&colon;`): numeric and the relevant named references.
        var result = text
        let named = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&apos;": "'", "&colon;": ":", "&Tab;": "\t", "&NewLine;": "\n"]
        for (entity, value) in named { result = result.replacingOccurrences(of: entity, with: value, options: .caseInsensitive) }
        let pattern = #"&#(x[0-9a-fA-F]{1,6}|[0-9]{1,7});?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return result }
        let ns = result as NSString
        var output = ""
        var last = 0
        for match in regex.matches(in: result, range: NSRange(location: 0, length: ns.length)) {
            output += ns.substring(with: NSRange(location: last, length: match.range.location - last))
            let body = ns.substring(with: match.range(at: 1))
            let value = body.hasPrefix("x") || body.hasPrefix("X") ? UInt32(body.dropFirst(), radix: 16) : UInt32(body)
            if let value, let scalar = Unicode.Scalar(value) { output.unicodeScalars.append(scalar) }
            last = match.range.location + match.range.length
        }
        output += ns.substring(from: last)
        return output
    }

    private static func appendEscaped(_ char: Unicode.Scalar, to out: inout String.UnicodeScalarView) {
        switch char {
        case "<": out.append(contentsOf: "&lt;".unicodeScalars)
        case ">": out.append(contentsOf: "&gt;".unicodeScalars)
        default: out.append(char)
        }
    }

    private static func escapeAttribute(_ text: String) -> String {
        text.replacing("&", with: "&amp;").replacing("\"", with: "&quot;").replacing("<", with: "&lt;").replacing(">", with: "&gt;")
    }

    private static func isASCIILetter(_ char: Unicode.Scalar) -> Bool {
        ("a"..."z").contains(char) || ("A"..."Z").contains(char)
    }

    private static func isSpace(_ char: Unicode.Scalar) -> Bool {
        char == " " || char == "\t" || char == "\n" || char == "\r" || char == "\u{0C}"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
