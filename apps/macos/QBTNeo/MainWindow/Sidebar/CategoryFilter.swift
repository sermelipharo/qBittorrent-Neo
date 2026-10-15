import Foundation

/// Category filter: All, Uncategorized, or a category (subcategories included).
enum CategoryFilter: Hashable, Sendable {
    case all
    case uncategorized
    case category(String)

    func matches(_ category: String) -> Bool {
        switch self {
        case .all: true
        case .uncategorized: category.isEmpty
        case .category(let name): category == name || category.hasPrefix(name + "/")
        }
    }
}
