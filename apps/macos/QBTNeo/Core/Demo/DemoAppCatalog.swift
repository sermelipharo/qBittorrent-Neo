import Foundation

/// Sample cookies and network interfaces for the demo session.
enum DemoAppCatalog {
    static var cookies: [Cookie] {
        let inYear = Int64(Date.now.timeIntervalSince1970) + 365 * 86_400
        let inMonth = Int64(Date.now.timeIntervalSince1970) + 30 * 86_400
        return [
            Cookie(name: "session_id", domain: ".academictorrents.com", path: "/", value: "c2f1e0b7a9d84e5f", expirationDate: inYear),
            Cookie(name: "uid", domain: "tracker.example.org", path: "/", value: "48213", expirationDate: inMonth),
            Cookie(name: "pass", domain: "tracker.example.org", path: "/", value: "9e107d9d372bb6826bd81d3542a419d6", expirationDate: inMonth),
            Cookie(name: "cf_clearance", domain: ".linuxtracker.org", path: "/", value: "k1Jx8.Qz-1760000000-0-1", expirationDate: inYear),
        ]
    }

    static let interfaces: [NetworkInterface] = [
        NetworkInterface(name: "Wi-Fi", value: "en0", addresses: ["192.168.1.23", "fe80::1c4e:9aff:fe2b:7d10", "2a02:8109:b6c0:4e00::1f3"]),
        NetworkInterface(name: "Ethernet", value: "en1", addresses: ["10.0.0.42"]),
        NetworkInterface(name: "WireGuard (utun3)", value: "utun3", addresses: ["10.66.0.5", "fd00:66::5"]),
        NetworkInterface(name: "Loopback", value: "lo0", addresses: ["127.0.0.1", "::1"]),
    ]
}
