import SwiftUI

/// WebUI › Security, Host header validation, custom headers, reverse proxy.
struct WebUISecuritySection: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        Section("Security") {
            Toggle("Enable clickjacking protection", isOn: $model.draft.webui.webUiClickjackingProtectionEnabled)
            Toggle("Enable Cross-Site Request Forgery (CSRF) protection", isOn: $model.draft.webui.webUiCsrfProtectionEnabled)
            Toggle("Enable cookie Secure flag (requires HTTPS or localhost connection)", isOn: $model.draft.webui.webUiSecureCookieEnabled)
        }
        CheckableSection(title: "Enable Host header validation", isOn: $model.draft.webui.webUiHostHeaderValidationEnabled) {
            CommitTextField(title: "Server domains:", text: $model.draft.webui.webUiDomainList, prompt: "*", trims: true)
                .help("""
                    Whitelist for filtering HTTP Host header values.
                    In order to defend against DNS rebinding attack,
                    you should put in domain names used by WebUI server.

                    Use ';' to split multiple entries. Can use wildcard '*'.
                    """)
        }
        CheckableSection(title: "Add custom HTTP headers", isOn: $model.draft.webui.webUiUseCustomHttpHeadersEnabled) {
            CommitTextEditor(
                title: "Add custom HTTP headers", text: $model.draft.webui.webUiCustomHttpHeaders,
                prompt: String(localized: "Header: value pairs, one per line")
            )
        }
        CheckableSection(title: "Enable reverse proxy support", isOn: $model.draft.webui.webUiReverseProxyEnabled) {
            CommitTextField(title: "Trusted proxies list:", text: $model.draft.webui.webUiReverseProxiesList, prompt: "10.0.0.0/8;127.0.0.1", trims: true)
                .help("""
                    Specify reverse proxy IPs (or subnets, e.g. 0.0.0.0/24) in order to use forwarded client address \
                    (X-Forwarded-For header). Use ';' to split multiple entries.
                    """)
            Link("Reverse proxy setup examples", destination: PreferenceLinks.reverseProxy)
        }
    }
}
