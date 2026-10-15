import Foundation

/// A node of the sidebar category tree (`a/b/c` → a › b › c).
struct CategoryNode: Identifiable, Equatable, Sendable {
    /// Full category name.
    let id: String
    let name: String
    var children: [Self]?

    /// Builds the tree from category names (missing parents are implied).
    static func tree(from names: [String]) -> [Self] {
        var childNames: [String: [String]] = [:]
        var all = Set(names)
        for name in names {
            for ancestor in CategoryStore.ancestors(of: name) { all.insert(ancestor) }
        }
        var roots: [String] = []
        for name in all {
            if let parent = CategoryStore.ancestors(of: name).last {
                childNames[parent, default: []].append(name)
            } else {
                roots.append(name)
            }
        }
        func build(_ name: String) -> Self {
            let kids = (childNames[name] ?? []).sorted(by: natural).map(build)
            let short = name.split(separator: "/").last.map(String.init) ?? name
            return Self(id: name, name: short, children: kids.isEmpty ? nil : kids)
        }
        return roots.sorted(by: natural).map(build)
    }

    private static func natural(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedStandardCompare(rhs) == .orderedAscending
    }
}
