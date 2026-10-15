import Foundation

/// Application-level calls used by Preferences, Cookies and About
/// (`api_app.rs`). 
protocol AppInfoClient: AnyObject, Sendable {
    func networkInterfaces() -> [NetworkInterface]
    func networkInterfaceAddresses(interface: String) -> [String]
    func cookies() -> [Cookie]
    func setCookies(cookies: [Cookie]) throws
    func sendTestEmail() async throws
    /// WebAPI-style partial update; used for `web_ui_password`, which the
    /// core hashes (PBKDF2) before storing.
    func setPreferencesJson(json: String) throws
    /// WebUI server state (listening URL, start-up error, temporary password).
    func webuiStatus() -> WebUiStatus
    /// PBKDF2-HMAC-SHA512 hash of the UI-lock password (the same format as
    /// the WebUI password); only the hash is ever stored.
    func hashUiLockPassword(password: String) async throws -> String
    func verifyUiLockPassword(stored: String, password: String) async throws -> Bool
    /// Raw favicon bytes (at most 64 KiB) of a tracker, fetched by the core
    /// through its HTTP client (general-purpose proxy applies).
    func fetchTrackerFavicon(trackerUrl: String) async throws -> Data
}
