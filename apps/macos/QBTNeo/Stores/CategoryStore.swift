import Foundation
import Observation

/// Categories (with their save paths) kept in sync from `MainDataUpdate`.
@Observable @MainActor
final class CategoryStore {
    private(set) var categories: [String: Category] = [:]
    /// Names sorted naturally and case-insensitively (qBittorrent order).
    private(set) var sortedNames: [String] = []
    /// Subcategory tree for the sidebar.
    private(set) var tree: [CategoryNode] = []

    func apply(changed: [Category], removed: [String], fullUpdate: Bool) {
        guard fullUpdate || !changed.isEmpty || !removed.isEmpty else { return }
        var next = fullUpdate ? [:] : categories
        for name in removed { next[name] = nil }
        for category in changed { next[category.name] = category }
        guard next != categories else { return }
        categories = next
        sortedNames = next.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        tree = CategoryNode.tree(from: sortedNames)
    }

    func category(named name: String) -> Category? { categories[name] }

    /// qBittorrent's category name rule: no backslash, no leading/trailing
    /// `/`, no `//`.
    nonisolated static func isValidName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        return !name.contains("\\") && !name.hasPrefix("/") && !name.hasSuffix("/") && !name.contains("//")
    }

    /// Parent category names of `a/b/c`: `a`, `a/b`.
    nonisolated static func ancestors(of name: String) -> [String] {
        let parts = name.split(separator: "/").map(String.init)
        guard parts.count > 1 else { return [] }
        return (1..<parts.count).map { parts.prefix($0).joined(separator: "/") }
    }
}
