import Foundation

/// Documentation links shown on the Settings pages.
enum PreferenceLinks {
    // swiftlint:disable force_unwrapping
    static let anonymousMode = URL(string: "https://github.com/qbittorrent/qBittorrent/wiki/Anonymous-Mode")!
    static let certificates = URL(string: "https://httpd.apache.org/docs/current/ssl/ssl_faq.html#aboutcerts")!
    static let alternativeWebUIs = URL(string: "https://github.com/qbittorrent/qBittorrent/wiki/List-of-known-alternate-WebUIs")!
    static let reverseProxy = URL(string: "https://github.com/qbittorrent/qBittorrent/wiki#reverse-proxy-setup-for-webui-access")!
    static let dynDNSRegister = URL(string: "https://account.dyn.com/entrance/")!
    static let noIPRegister = URL(string: "https://www.noip.com/remote-access")!
    static let advancedDocs = URL(string: "https://github.com/qbittorrent/qBittorrent/wiki/Explanation-of-Options-in-qBittorrent#Advanced")!
    static let libtorrentDocs = URL(string: "https://www.libtorrent.org/reference-Settings.html")!
    static let searchPlugins = URL(string: "https://plugins.qbittorrent.org")!
    // swiftlint:enable force_unwrapping
}
