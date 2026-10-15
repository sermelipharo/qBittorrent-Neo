import SwiftUI

/// General › Notifications: system notifications, a link to the app's
/// notification settings, and the completion e-mail (its server fields
/// appear only while the e-mail is on).
struct NotificationsGroup: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui
    @Environment(\.openURL) private var openURL
    @State private var isSending = false
    @State private var notice: PreferencesNotice?

    var body: some View {
        @Bindable var gui = gui
        let mail = model.draft.downloads.mailNotificationEnabled
        SettingsGroup(.notifications) {
            Toggle(SettingsCatalog.title("GUI/Notifications/Enabled"), isOn: $gui.notificationsEnabled)
                .setting("GUI/Notifications/Enabled")
        } content: {
            Toggle(SettingsCatalog.title("Application/GUI/Notifications/TorrentAdded"), isOn: $gui.notifyTorrentAdded)
                .disabled(!gui.notificationsEnabled)
                .setting("Application/GUI/Notifications/TorrentAdded", indented: true)
            Button(SettingsCatalog.title("system.notificationSettings"), action: openNotificationSettings)
                .setting("system.notificationSettings")
            Toggle(SettingsCatalog.title("mail_notification_enabled"), isOn: $model.draft.downloads.mailNotificationEnabled)
                .setting("mail_notification_enabled")
            if mail {
                mailFields
            }
        }
    }

    @ViewBuilder private var mailFields: some View {
        CommitTextField(title: SettingsCatalog.key("mail_notification_sender"),
                        text: $model.draft.downloads.mailNotificationSender, trims: true)
            .setting("mail_notification_sender")
        CommitTextField(title: SettingsCatalog.key("mail_notification_email"),
                        text: $model.draft.downloads.mailNotificationEmail, trims: true)
            .setting("mail_notification_email")
        CommitTextField(title: SettingsCatalog.key("mail_notification_smtp"),
                        text: $model.draft.downloads.mailNotificationSmtp, prompt: "smtp.example.com:587", trims: true)
            .setting("mail_notification_smtp")
        Toggle(SettingsCatalog.title("mail_notification_ssl_enabled"), isOn: $model.draft.downloads.mailNotificationSslEnabled)
            .setting("mail_notification_ssl_enabled")
        Toggle(SettingsCatalog.title("mail_notification_auth_enabled"), isOn: $model.draft.downloads.mailNotificationAuthEnabled)
            .setting("mail_notification_auth_enabled")
        if model.draft.downloads.mailNotificationAuthEnabled {
            CommitTextField(title: SettingsCatalog.key("mail_notification_username"),
                            text: $model.draft.downloads.mailNotificationUsername, trims: true)
                .setting("mail_notification_username")
            CommitTextField(title: SettingsCatalog.key("mail_notification_password"),
                            text: $model.draft.downloads.mailNotificationPassword, isSecure: true)
                .setting("mail_notification_password")
        }
        HStack(spacing: Design.Spacing.regular) {
            Button(SettingsCatalog.title("system.testEmail"), action: sendTestEmail)
                .disabled(isSending || model.appInfo == nil)
            if isSending {
                ProgressView()
                    .controlSize(.small)
            } else if let notice {
                InlineMessage(text: notice.text, style: notice.isError ? .error : .info)
            }
        }
        .setting("system.testEmail")
    }

    /// System Settings › Notifications › this app (HIG: respect system settings).
    private func openNotificationSettings() {
        let bundleID = Bundle.main.bundleIdentifier ?? ""
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension?id=\(bundleID)") {
            openURL(url)
        }
    }

    private func sendTestEmail() {
        guard let client = model.appInfo else { return }
        isSending = true
        Task {
            await model.applyNow()
            do {
                try await client.sendTestEmail()
                notice = PreferencesNotice(text: String(localized: "Attempted to send email. Check your inbox to confirm success"), isError: false)
            } catch {
                notice = PreferencesNotice(text: error.userMessage, isError: true)
            }
            isSending = false
        }
    }
}
