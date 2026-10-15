import Foundation
import Observation

/// The UI lock (features.md §1.3.6): a PBKDF2 password hash and the locked
/// flag, both persisted in `UserDefaults` under qBittorrent's keys
/// (`Locking/password_PBKDF2`, `Locking/locked`). The password itself is
/// never stored; hashing and verification run in the core (PBKDF2-HMAC-SHA512,
/// 100,000 iterations, random salt, constant-time comparison).
@Observable @MainActor
final class UILockModel {
    /// qBittorrent's minimum password length.
    static let minimumPasswordLength = 3

    private(set) var isLocked: Bool
    private(set) var hasPassword: Bool
    private(set) var isBusy = false
    /// Message of the last failed unlock attempt.
    private(set) var unlockError: String?

    @ObservationIgnored var clientProvider: @MainActor () -> (any AppInfoClient)? = { nil }
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var failedAttempts = 0
    @ObservationIgnored private var lockedOutUntil = Date.distantPast

    init(defaults: UserDefaults = AppDefaults.store) {
        self.defaults = defaults
        let hasPassword = !(defaults.string(forKey: GUIPreferenceKey.lockPasswordHash.rawValue) ?? "").isEmpty
        self.hasPassword = hasPassword
        // A lock without a password can never be released, so it is ignored.
        isLocked = hasPassword && defaults.bool(forKey: GUIPreferenceKey.locked.rawValue)
    }

    private var storedHash: String {
        defaults.string(forKey: GUIPreferenceKey.lockPasswordHash.rawValue) ?? ""
    }

    /// Locks the UI. Requires a password; returns false when none is set.
    @discardableResult
    func engage() -> Bool {
        guard hasPassword else { return false }
        isLocked = true
        unlockError = nil
        defaults.set(true, forKey: GUIPreferenceKey.locked.rawValue)
        return true
    }

    /// Hashes and stores `password`; returns an error message on failure.
    func setPassword(_ password: String) async -> String? {
        guard password.count >= Self.minimumPasswordLength else {
            return String(localized: "The password must be at least 3 characters long")
        }
        guard let client = clientProvider() else { return String(localized: "The password is invalid") }
        isBusy = true
        defer { isBusy = false }
        do {
            let hash = try await client.hashUiLockPassword(password: password)
            defaults.set(hash, forKey: GUIPreferenceKey.lockPasswordHash.rawValue)
            hasPassword = true
            return nil
        } catch {
            return error.userMessage
        }
    }

    func clearPassword() {
        defaults.removeObject(forKey: GUIPreferenceKey.lockPasswordHash.rawValue)
        defaults.set(false, forKey: GUIPreferenceKey.locked.rawValue)
        hasPassword = false
        isLocked = false
    }

    /// Verifies `password` and unlocks on success. Repeated failures are
    /// throttled (exponential delay, at most 30 s) against guessing.
    func unlock(with password: String) async -> Bool {
        guard isLocked, !isBusy else { return !isLocked }
        guard await verify(password) else { return false }
        isLocked = false
        defaults.set(false, forKey: GUIPreferenceKey.locked.rawValue)
        return true
    }

    /// Checks `password` against the stored hash with the same throttling as
    /// `unlock(with:)`, without changing the lock state.
    func verify(_ password: String) async -> Bool {
        if Date.now < lockedOutUntil {
            let seconds = Int(lockedOutUntil.timeIntervalSinceNow.rounded(.up))
            unlockError = String(localized: "Too many attempts. Try again in \(seconds) seconds.")
            return false
        }
        guard let client = clientProvider() else {
            unlockError = String(localized: "The password is invalid")
            return false
        }
        isBusy = true
        defer { isBusy = false }
        let valid = (try? await client.verifyUiLockPassword(stored: storedHash, password: password)) ?? false
        if valid {
            failedAttempts = 0
            unlockError = nil
            return true
        }
        failedAttempts += 1
        if failedAttempts >= 3 {
            lockedOutUntil = .now.addingTimeInterval(min(pow(2, Double(failedAttempts - 2)), 30))
        }
        unlockError = String(localized: "The password is invalid")
        return false
    }
}
