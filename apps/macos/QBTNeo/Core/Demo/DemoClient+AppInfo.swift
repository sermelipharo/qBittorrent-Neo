import Foundation

extension DemoClient: AppInfoClient {
    func networkInterfaces() -> [NetworkInterface] {
        DemoAppCatalog.interfaces
    }

    func networkInterfaceAddresses(interface: String) -> [String] {
        let interfaces = DemoAppCatalog.interfaces
        if interface.isEmpty { return interfaces.flatMap(\.addresses) }
        return interfaces.first { $0.value == interface }?.addresses ?? []
    }

    func cookies() -> [Cookie] {
        DemoFeatureStore.shared.cookies.withLock { $0 }
    }

    func setCookies(cookies: [Cookie]) throws {
        let now = Int64(Date.now.timeIntervalSince1970)
        DemoFeatureStore.shared.cookies.withLock { $0 = cookies.filter { $0.expirationDate > now } }
    }

    func sendTestEmail() async throws {
        try await Task.sleep(for: .seconds(1))
    }

    func setPreferencesJson(json: String) throws {
        guard let object = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else {
            throw QbtError.InvalidArgument(message: "preferences must be a JSON object")
        }
        if let password = object["web_ui_password"] as? String {
            guard password.count >= 6 else {
                throw QbtError.InvalidArgument(message: "WebUI password must be at least 6 characters long")
            }
            var prefs = preferences()
            prefs.webui.webUiPasswordPbkdf2 = "@ByteArray(\(DemoRandom.hex(password, length: 24)):\(DemoRandom.hex(password + "#", length: 88)))"
            try setPreferences(prefs: prefs)
        }
    }

    func webuiStatus() -> WebUiStatus {
        let webui = preferences().webui
        let hasPassword = !webui.webUiPasswordPbkdf2.isEmpty
        return WebUiStatus(
            enabled: webui.webUiEnabled, running: webui.webUiEnabled, https: webui.useHttps, address: webui.webUiAddress,
            port: UInt16(clamping: webui.webUiPort), url: "\(webui.useHttps ? "https" : "http")://localhost:\(webui.webUiPort)",
            error: "", username: webui.webUiUsername, temporaryPassword: webui.webUiEnabled && !hasPassword ? "Fq7kM2xpa" : ""
        )
    }

    func hashUiLockPassword(password: String) async throws -> String {
        "demo:" + DemoRandom.hex(password, length: 32)
    }

    func verifyUiLockPassword(stored: String, password: String) async throws -> Bool {
        stored == "demo:" + DemoRandom.hex(password, length: 32)
    }

    func checkPort(port: Int64) async throws -> Bool {
        try await Task.sleep(for: .seconds(1))
        return true
    }

    func fetchTrackerFavicon(trackerUrl: String) async throws -> Data {
        throw QbtError.Network(message: "favicons are not available in demo mode")
    }
}
