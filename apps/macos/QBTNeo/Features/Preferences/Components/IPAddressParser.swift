import Darwin
import Foundation

/// IPv4/IPv6 address and subnet parsing with canonical formatting (the
/// `QHostAddress` checks of the Banned IPs and IP subnet whitelist dialogs).
enum IPAddressParser {
    /// Canonical text of an IPv4/IPv6 address (RFC 5952 for IPv6), or nil.
    static func normalizedAddress(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var v4 = in_addr()
        if inet_pton(AF_INET, trimmed, &v4) == 1 {
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            guard inet_ntop(AF_INET, &v4, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else { return nil }
            return String(utf8String: buffer)
        }
        var v6 = in6_addr()
        if inet_pton(AF_INET6, trimmed, &v6) == 1 {
            var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            guard inet_ntop(AF_INET6, &v6, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil else { return nil }
            return String(utf8String: buffer)
        }
        return nil
    }

    /// Canonical `address/prefix` of a subnet; a bare address is a host subnet.
    static func normalizedSubnet(_ text: String) -> String? {
        let parts = text.trimmingCharacters(in: .whitespaces).split(separator: "/", omittingEmptySubsequences: false)
        guard (1...2).contains(parts.count), let address = normalizedAddress(String(parts[0])) else { return nil }
        let maxPrefix = address.contains(":") ? 128 : 32
        guard parts.count == 2 else { return "\(address)/\(maxPrefix)" }
        guard let prefix = Int(parts[1]), (0...maxPrefix).contains(prefix) else { return nil }
        return "\(address)/\(prefix)"
    }
}
