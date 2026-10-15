import Foundation

/// A one-off result message shown next to a setting (password changed,
/// test e-mail sent, filter reloaded, …).
struct PreferencesNotice: Equatable {
    let text: String
    let isError: Bool
}
