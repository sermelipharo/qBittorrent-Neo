import Foundation

/// qBittorrent's `Path` operations on relative torrent paths (`/`-separated),
/// as the Manage Torrent Content dialog uses them.
enum ContentPath {
    /// `Path(QString)`: text with a separator is cleaned like
    /// `QDir::cleanPath` (`\` counts as `/`, as in the core): repeated
    /// separators, `.` components and a trailing `/` go, `..` removes the
    /// component before it. Text without a separator is kept as is.
    static func clean(_ text: String) -> String {
        guard text.contains("/") || text.contains("\\") else { return text }
        let normalized = text.replacing("\\", with: "/")
        let isAbsolute = normalized.hasPrefix("/")
        var parts: [Substring] = []
        for part in normalized.split(separator: "/") where part != "." {
            if part == "..", let last = parts.last, last != ".." {
                parts.removeLast()
            } else if part == "..", isAbsolute, parts.isEmpty {
                continue
            } else {
                parts.append(part)
            }
        }
        let joined = parts.joined(separator: "/")
        if isAbsolute { return "/" + joined }
        return joined.isEmpty ? "." : joined
    }

    /// `Path::commonPath`: the leading components two paths share.
    static func common(_ left: String, _ right: String) -> String {
        guard !left.isEmpty, !right.isEmpty else { return "" }
        let lhs = left.split(separator: "/", omittingEmptySubsequences: false)
        let rhs = right.split(separator: "/", omittingEmptySubsequences: false)
        var count = 0
        while count < lhs.count, count < rhs.count, lhs[count] == rhs[count] { count += 1 }
        return lhs.prefix(count).joined(separator: "/")
    }

    /// `Path::commonPath(PathList)`; nil without paths. One path is its own common path.
    static func common(_ paths: some Sequence<String>) -> String? {
        var result: String?
        for path in paths {
            guard let current = result else {
                result = path
                continue
            }
            let shared = common(current, path)
            if shared.isEmpty { return "" }
            result = shared
        }
        return result
    }

    /// `base.relativePathOf(path)`: "" for the base itself, `../` steps for a
    /// path outside it; the path itself when the base is empty.
    static func relative(_ path: String, to base: String) -> String {
        guard !base.isEmpty else { return path }
        if path == base { return "" }
        if path.hasPrefix(base + "/") { return String(path.dropFirst(base.count + 1)) }
        let baseParts = base.split(separator: "/")
        let pathParts = path.split(separator: "/")
        var shared = 0
        while shared < baseParts.count, shared < pathParts.count, baseParts[shared] == pathParts[shared] { shared += 1 }
        let up = Array(repeating: "..", count: baseParts.count - shared)
        return (up + pathParts[shared...].map(String.init)).joined(separator: "/")
    }

    /// `base / relative`, cleaned.
    static func join(_ base: String, _ relative: String) -> String {
        if relative.isEmpty { return base }
        if base.isEmpty { return relative }
        return clean(base + "/" + relative)
    }
}
