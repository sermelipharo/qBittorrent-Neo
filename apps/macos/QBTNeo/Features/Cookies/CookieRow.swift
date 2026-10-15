import Foundation

/// An editable cookie in the Manage Cookies window.
struct CookieRow: Identifiable, Equatable {
    let id: UUID
    var domain: String
    var path: String
    var name: String
    var value: String
    var expiration: Date

    init(id: UUID = UUID(), domain: String = "", path: String = "/", name: String = "", value: String = "", expiration: Date) {
        self.id = id
        self.domain = domain
        self.path = path
        self.name = name
        self.value = value
        self.expiration = expiration
    }

    init(_ cookie: Cookie) {
        self.init(
            domain: cookie.domain, path: cookie.path, name: cookie.name, value: cookie.value,
            expiration: Date(timeIntervalSince1970: TimeInterval(cookie.expirationDate))
        )
    }

    var cookie: Cookie {
        Cookie(
            name: name.trimmingCharacters(in: .whitespaces), domain: domain.trimmingCharacters(in: .whitespaces),
            path: path.isEmpty ? "/" : path, value: value, expirationDate: Int64(expiration.timeIntervalSince1970)
        )
    }
}
