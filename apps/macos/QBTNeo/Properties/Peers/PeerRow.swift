import Foundation

/// A Peers tab row keyed by (IP, port, connection type), like qBittorrent.
struct PeerRow: Identifiable, Equatable, Sendable {
    let id: String
    var info: PeerInfo

    init(_ info: PeerInfo) {
        id = "\(info.ip)|\(info.port)|\(info.connectionType)"
        self.info = info
    }

    /// `ip:port`, IPv6 as `[ip]:port`.
    var endpoint: String {
        info.ip.contains(":") && !info.ip.contains(".") ? "[\(info.ip)]:\(info.port)" : "\(info.ip):\(info.port)"
    }

    /// Regional-indicator flag emoji for the ISO country code.
    var flag: String {
        let base: UInt32 = 0x1F1E6 - 65
        let scalars = info.countryCode.uppercased().unicodeScalars.compactMap { UnicodeScalar(base + $0.value) }
        guard scalars.count == 2 else { return "" }
        return String(String.UnicodeScalarView(scalars))
    }
}
