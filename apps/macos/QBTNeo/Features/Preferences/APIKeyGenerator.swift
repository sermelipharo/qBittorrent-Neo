import Foundation

/// WebUI API keys (`Utils::APIKey`): `qbt_` followed by 28 characters from
/// an alphabet without look-alike characters, from the system CSPRNG.
enum APIKeyGenerator {
    static let prefix = "qbt_"
    static let randomLength = 28
    private static let alphabet = Array("23456789ABCDEFGHIJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz")

    static func generate() -> String {
        var generator = SystemRandomNumberGenerator()
        let body = (0..<randomLength).map { _ in alphabet[Int.random(in: 0..<alphabet.count, using: &generator)] }
        return prefix + String(body)
    }

    static func isValid(_ key: String) -> Bool {
        key.count == prefix.count + randomLength && key.hasPrefix(prefix)
    }

    /// Masked display: first 4 characters, `•` × (length − 10), last 6.
    static func masked(_ key: String) -> String {
        guard key.count > 10 else { return key }
        return String(key.prefix(4)) + String(repeating: "•", count: key.count - 10) + String(key.suffix(6))
    }
}
