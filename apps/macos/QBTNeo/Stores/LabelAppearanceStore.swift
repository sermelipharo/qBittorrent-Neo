import Foundation
import Observation

/// Icons and colors of categories and tags, keyed by name, persisted in the
/// profile's GUI settings (`AppDefaults`), so they survive restarts and stay
/// with their profile. Entries go away with their category (and its
/// subcategories) or tag, whether removed here or through the WebUI.
@Observable @MainActor
final class LabelAppearanceStore {
    static let categoriesKey = "GUI/TransferList/CategoryAppearance"
    static let tagsKey = "GUI/TransferList/TagAppearance"

    private(set) var categories: [String: LabelAppearance]
    private(set) var tags: [String: LabelAppearance]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = AppDefaults.store) {
        self.defaults = defaults
        categories = Self.load(defaults, Self.categoriesKey)
        tags = Self.load(defaults, Self.tagsKey)
    }

    /// How a category is shown: its own icon and color, each falling back to the nearest
    /// parent category's (`Movies/4K` without its own looks like `Movies`).
    func category(_ name: String) -> LabelAppearance {
        var result = categories[name] ?? LabelAppearance()
        for ancestor in CategoryStore.ancestors(of: name).reversed() where result.symbol == nil || result.color == nil {
            let parent = categories[ancestor] ?? LabelAppearance()
            result.symbol = result.symbol ?? parent.symbol
            result.color = result.color ?? parent.color
        }
        return result
    }

    /// The icon and color set on the category itself (the editor's values).
    func ownCategory(_ name: String) -> LabelAppearance { categories[name] ?? LabelAppearance() }

    func tag(_ name: String) -> LabelAppearance { tags[name] ?? LabelAppearance() }

    func setCategory(_ name: String, _ appearance: LabelAppearance) {
        guard !name.isEmpty, categories[name] ?? LabelAppearance() != appearance else { return }
        categories[name] = appearance.isDefault ? nil : appearance
        save(categories, Self.categoriesKey)
    }

    func setTag(_ name: String, _ appearance: LabelAppearance) {
        guard !name.isEmpty, tags[name] ?? LabelAppearance() != appearance else { return }
        tags[name] = appearance.isDefault ? nil : appearance
        save(tags, Self.tagsKey)
    }

    /// Forgets removed categories and their subcategories (`a` also removes `a/b`).
    func removeCategories(_ names: [String]) {
        let next = categories.filter { entry in
            !names.contains { entry.key == $0 || entry.key.hasPrefix($0 + "/") }
        }
        guard next.count != categories.count else { return }
        categories = next
        save(categories, Self.categoriesKey)
    }

    func removeTags(_ names: [String]) {
        let next = tags.filter { !names.contains($0.key) }
        guard next.count != tags.count else { return }
        tags = next
        save(tags, Self.tagsKey)
    }

    private func save(_ entries: [String: LabelAppearance], _ key: String) {
        if entries.isEmpty {
            defaults.removeObject(forKey: key)
        } else {
            defaults.set(entries.mapValues(\.storage), forKey: key)
        }
    }

    private static func load(_ defaults: UserDefaults, _ key: String) -> [String: LabelAppearance] {
        guard let stored = defaults.dictionary(forKey: key) as? [String: [String: String]] else { return [:] }
        return stored.mapValues(LabelAppearance.init(storage:)).filter { !$0.value.isDefault }
    }
}
