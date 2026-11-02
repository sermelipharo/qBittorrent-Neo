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

    /// A banned-list entry (qBittorrent 5.3 `parseIPRange`): an address, a
    /// subnet (`10.0.0.0/8`) or a range (`10.0.0.1 - 10.0.0.9`), as the
    /// core stores it: the address alone, or `first - last`.
    static func normalizedBanEntry(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let range: (first: [UInt8], last: [UInt8])
        if let dash = trimmed.firstIndex(of: "-") {
            guard let first = bytes(String(trimmed[..<dash])), let last = bytes(String(trimmed[trimmed.index(after: dash)...])) else {
                return nil
            }
            range = (first, last)
        } else if let slash = trimmed.firstIndex(of: "/") {
            guard let network = bytes(String(trimmed[..<slash])),
                  let prefix = Int(trimmed[trimmed.index(after: slash)...]), (0...network.count * 8).contains(prefix) else { return nil }
            var first = network, last = network
            for bit in prefix..<(network.count * 8) {
                first[bit / 8] &= ~(0x80 >> UInt8(bit % 8))
                last[bit / 8] |= 0x80 >> UInt8(bit % 8)
            }
            range = (first, last)
        } else {
            guard let address = bytes(trimmed) else { return nil }
            range = (address, address)
        }
        guard range.first.count == range.last.count, !range.last.lexicographicallyPrecedes(range.first),
              let first = addressText(range.first), let last = addressText(range.last) else { return nil }
        return first == last ? first : "\(first) - \(last)"
    }

    /// Network-order bytes of an address (IPv4-mapped IPv6 as IPv4).
    private static func bytes(_ text: String) -> [UInt8]? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var v4 = in_addr()
        if inet_pton(AF_INET, trimmed, &v4) == 1 { return withUnsafeBytes(of: &v4) { Array($0) } }
        var v6 = in6_addr()
        guard inet_pton(AF_INET6, trimmed, &v6) == 1 else { return nil }
        let raw = withUnsafeBytes(of: &v6) { Array($0) }
        return raw.prefix(10).allSatisfy { $0 == 0 } && raw[10] == 0xFF && raw[11] == 0xFF ? Array(raw.suffix(4)) : raw
    }

    private static func addressText(_ bytes: [UInt8]) -> String? {
        let family = bytes.count == 4 ? AF_INET : AF_INET6
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        return bytes.withUnsafeBytes { raw in
            inet_ntop(family, raw.baseAddress, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil ? String(utf8String: buffer) : nil
        }
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
