import Foundation

/// Tells whether a setting still has its default value, for the "advanced
/// settings on this pane are changed" counter. Reads the draft preferences or
/// the GUI preferences; hiding a setting never changes its value.
@MainActor
struct SettingCheck {
    let isDefault: @MainActor (Preferences, GUIPreferences) -> Bool

    /// A core preference compared with qBittorrent's default.
    static func pref<Value: Equatable>(_ path: KeyPath<Preferences, Value>) -> Self {
        Self { prefs, _ in prefs[keyPath: path] == Preferences.qbtDefaults[keyPath: path] }
    }

    /// Several core preferences, all at their defaults.
    static func prefs<A: Equatable, B: Equatable>(_ first: KeyPath<Preferences, A>, _ second: KeyPath<Preferences, B>) -> Self {
        Self { prefs, _ in
            prefs[keyPath: first] == Preferences.qbtDefaults[keyPath: first]
                && prefs[keyPath: second] == Preferences.qbtDefaults[keyPath: second]
        }
    }

    /// A GUI-only preference compared with its default.
    static func gui<Value: Equatable>(_ path: KeyPath<GUIPreferences, Value>, _ defaultValue: Value) -> Self {
        Self { _, gui in gui[keyPath: path] == defaultValue }
    }

    /// A `UserDefaults` integer (settings kept outside `GUIPreferences`).
    static func defaults(_ key: String, _ defaultValue: Int) -> Self {
        Self { _, _ in (AppDefaults.store.object(forKey: key) as? Int ?? defaultValue) == defaultValue }
    }
}
