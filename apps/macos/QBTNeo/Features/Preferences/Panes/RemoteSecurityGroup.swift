import SwiftUI

/// Remote › Security (advanced): clickjacking, CSRF, cookie, Host header
/// validation, custom headers and reverse proxy support. Defaults and
/// warnings are qBittorrent's; this is a layout change only.
struct RemoteSecurityGroup: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        let webui = model.draft.webui
        SettingsGroup(.webUISecurity) {
            Toggle(SettingsCatalog.title("web_ui_clickjacking_protection_enabled"), isOn: $model.draft.webui.webUiClickjackingProtectionEnabled)
                .setting("web_ui_clickjacking_protection_enabled")
        } content: {
            Toggle(SettingsCatalog.title("web_ui_csrf_protection_enabled"), isOn: $model.draft.webui.webUiCsrfProtectionEnabled)
                .setting("web_ui_csrf_protection_enabled")
            Toggle(SettingsCatalog.title("web_ui_secure_cookie_enabled"), isOn: $model.draft.webui.webUiSecureCookieEnabled)
                .setting("web_ui_secure_cookie_enabled")
            Toggle(SettingsCatalog.title("web_ui_host_header_validation_enabled"), isOn: $model.draft.webui.webUiHostHeaderValidationEnabled)
                .setting("web_ui_host_header_validation_enabled")
            CommitTextField(title: "Server domains:", text: $model.draft.webui.webUiDomainList, prompt: "*", trims: true)
                .help("""
                    Whitelist for filtering HTTP Host header values.
                    In order to defend against DNS rebinding attack,
                    you should put in domain names used by WebUI server.

                    Use ';' to split multiple entries. Can use wildcard '*'.
                    """)
                .disabled(!webui.webUiHostHeaderValidationEnabled)
            Toggle(SettingsCatalog.title("web_ui_use_custom_http_headers_enabled"), isOn: $model.draft.webui.webUiUseCustomHttpHeadersEnabled)
                .setting("web_ui_use_custom_http_headers_enabled")
            CommitTextEditor(title: SettingsCatalog.key("web_ui_use_custom_http_headers_enabled"), text: $model.draft.webui.webUiCustomHttpHeaders,
                             prompt: String(localized: "Header: value pairs, one per line"))
                .labelsHidden()
                .disabled(!webui.webUiUseCustomHttpHeadersEnabled)
            Toggle(SettingsCatalog.title("web_ui_reverse_proxy_enabled"), isOn: $model.draft.webui.webUiReverseProxyEnabled)
                .setting("web_ui_reverse_proxy_enabled")
            CommitTextField(title: "Trusted proxies list:", text: $model.draft.webui.webUiReverseProxiesList, prompt: "10.0.0.0/8;127.0.0.1", trims: true)
                .help("""
                    Specify reverse proxy IPs (or subnets, e.g. 0.0.0.0/24) in order to use forwarded client address \
                    (X-Forwarded-For header). Use ';' to split multiple entries.
                    """)
                .disabled(!webui.webUiReverseProxyEnabled)
            Link("Reverse proxy setup examples", destination: PreferenceLinks.reverseProxy)
        }
    }
}
