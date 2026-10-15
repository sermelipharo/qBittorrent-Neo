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
        #if DEBUG
        // Scripted UI runs must not raise the system permission prompt over the user's work.
        if ProcessInfo.processInfo.environment["QBT_UI_SCRIPT"] != nil { return }
        #endif
        do {
            authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            log("Permission for notifications not granted. Error: \"\(error.localizedDescription)\"")
        }
    }

    func post(title: String, body: String) {
        #if DEBUG
        if ProcessInfo.processInfo.environment["QBT_UI_SCRIPT"] != nil {
            FileHandle.standardError.write(Data("UIDRIVER: NOTIFICATION '\(title)': \(body)\n".utf8))
            return
        }
        #endif
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
