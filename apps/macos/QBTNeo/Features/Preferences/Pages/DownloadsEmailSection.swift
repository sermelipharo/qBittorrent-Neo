import SwiftUI

/// Downloads › "Email notification upon download completion".
struct DownloadsEmailSection: View {
    @Bindable var model: PreferencesModel
    @State private var isSending = false
    @State private var notice: PreferencesNotice?

    var body: some View {
        CheckableSection(title: "Email notification upon download completion", isOn: $model.draft.downloads.mailNotificationEnabled) {
            CommitTextField(title: "From:", text: $model.draft.downloads.mailNotificationSender, trims: true).settingAnchor("downloads.4")
                .help("Sender")
            CommitTextField(title: "To:", text: $model.draft.downloads.mailNotificationEmail, trims: true).settingAnchor("downloads.5")
                .help("Receiver")
            CommitTextField(title: "SMTP server:", text: $model.draft.downloads.mailNotificationSmtp, prompt: "smtp.example.com:587", trims: true)
                .settingAnchor("downloads.6")
            Toggle("This server requires a secure connection (SSL)", isOn: $model.draft.downloads.mailNotificationSslEnabled)
                .settingAnchor("downloads.7")
            Toggle("Authentication", isOn: $model.draft.downloads.mailNotificationAuthEnabled).settingAnchor("downloads.8")
            Group {
                CommitTextField(title: "Username:", text: $model.draft.downloads.mailNotificationUsername, trims: true).settingAnchor("downloads.9")
                CommitTextField(title: "Password:", text: $model.draft.downloads.mailNotificationPassword, isSecure: true)
                    .settingAnchor("downloads.10")
            }
            .disabled(!model.draft.downloads.mailNotificationAuthEnabled)
            .padding(.leading, Design.Spacing.xLarge)
            LabeledContent {
                Button("Send test email", action: sendTestEmail)
                    .disabled(isSending || model.appInfo == nil)
            } label: {
                if isSending {
                    ProgressView()
                        .controlSize(.small)
                } else if let notice {
                    InlineMessage(text: notice.text, style: notice.isError ? .error : .info)
                }
            }
        }.settingAnchor("downloads.3")
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
