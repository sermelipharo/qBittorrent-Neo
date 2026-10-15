import Foundation

/// Recently chosen palette rows (most recent first), kept in UserDefaults and
/// bounded; recent rows rank higher and are listed while the query is empty.
@MainActor
struct PaletteRecents {
    static let key = "CommandPalette/Recents"
    static let limit = 20

    private let defaults: UserDefaults
    private let isPersistent: Bool
    private(set) var ids: [String]

    init(defaults: UserDefaults = .standard, persistent: Bool = true) {
        self.defaults = defaults
        self.isPersistent = persistent
        ids = persistent ? Array((defaults.stringArray(forKey: Self.key) ?? []).prefix(Self.limit)) : []
    }

    mutating func record(_ id: String) {
        ids.removeAll { $0 == id }
        ids.insert(id, at: 0)
        if ids.count > Self.limit { ids.removeLast(ids.count - Self.limit) }
        if isPersistent { defaults.set(ids, forKey: Self.key) }
    }

    /// Ranking bonus: larger for more recent rows, zero for others.
    func boost(_ id: String) -> Int {
        guard let rank = ids.firstIndex(of: id) else { return 0 }
        return (Self.limit - rank) * 15
    }
}
