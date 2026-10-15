import Foundation
import UserNotifications

/// Desktop notifications through `UNUserNotificationCenter` (default sound,
/// UUID identifiers), as qBittorrent does on macOS.
@MainActor
final class NotificationManager {
    private var authorized = false
    private var requested = false

    func requestAuthorization(log: (String) -> Void) async {
        guard !requested else { return }
        requested = true
        do {
            authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            log("Permission for notifications not granted. Error: \"\(error.localizedDescription)\"")
        }
    }

    func post(title: String, body: String) {
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
