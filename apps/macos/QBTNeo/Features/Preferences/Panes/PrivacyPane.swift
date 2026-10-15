import SwiftUI

/// Settings › Privacy: encryption, VPN binding, proxy, IP blocking, app lock.
struct PrivacyPane: View {
    @Bindable var model: PreferencesModel
    @State private var network = NetworkInterfacesModel()

    var body: some View {
        SettingsPaneView(.privacy, model: model) {
            PrivacySummary(prefs: model.draft)
        } content: {
            SettingsGroup(.encryption) {
                Picker(SettingsCatalog.title("encryption"), selection: $model.draft.bittorrent.encryption) {
                    ForEach(PreferenceChoices.encryptionModes, id: \.self) { Text(PreferenceChoices.title($0)).tag($0) }
                }
                .fixedSize()
                .setting("encryption")
                HStack(spacing: Design.Spacing.regular) {
                    Toggle(SettingsCatalog.title("anonymous_mode"), isOn: $model.draft.bittorrent.anonymousMode)
                    Link("More information", destination: PreferenceLinks.anonymousMode)
                }
                .setting("anonymous_mode")
            }

            SettingsGroup(.vpn) {
                Picker(SettingsCatalog.title("current_network_interface"), selection: $model.draft.advanced.currentNetworkInterface) {
                    ForEach(network.interfaceChoices(selected: model.draft.advanced.currentNetworkInterface,
                                                     savedName: model.draft.advanced.currentInterfaceName), id: \.value) { choice in
                        Text(choice.title).tag(choice.value)
                    }
                }
                .fixedSize()
                .setting("current_network_interface")
                SettingsDisclosure(title: "Bind to address", section: .vpn) {
                    Picker(SettingsCatalog.title("current_interface_address"), selection: $model.draft.advanced.currentInterfaceAddress) {
                        ForEach(network.addressChoices(selected: model.draft.advanced.currentInterfaceAddress), id: \.value) { choice in
                            Text(choice.title).tag(choice.value)
                        }
                    }
                    .fixedSize()
                    .setting("current_interface_address")
                }
            }

            ProxyGroup(model: model)
            IPFilterGroup(model: model)

            SettingsGroup(.appLock) {
                LockPasswordRow()
                    .setting("Locking/password_PBKDF2")
                SettingFootnote(text: String(localized: "View › Lock hides the window until the password is entered."))
            }

            SettingsGroup(.downloadedFiles) {
                Toggle(SettingsCatalog.title("mark_of_the_web"), isOn: $model.draft.advanced.markOfTheWeb)
                    .setting("mark_of_the_web")
            } content: {
                EmptyView()
            }

            I2PGroup(model: model)

            SettingsGroup(.protection) {
                Toggle(SettingsCatalog.title("validate_https_tracker_certificate"), isOn: $model.draft.advanced.validateHttpsTrackerCertificate)
                    .setting("validate_https_tracker_certificate")
            } content: {
                Toggle(SettingsCatalog.title("ssrf_mitigation"), isOn: $model.draft.advanced.ssrfMitigation)
                    .setting("ssrf_mitigation")
                Toggle(SettingsCatalog.title("block_peers_on_privileged_ports"), isOn: $model.draft.advanced.blockPeersOnPrivilegedPorts)
                    .setting("block_peers_on_privileged_ports")
                Toggle(SettingsCatalog.title("idn_support_enabled"), isOn: $model.draft.advanced.idnSupportEnabled)
                    .setting("idn_support_enabled")
                VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                    Toggle(SettingsCatalog.title("ignore_ssl_errors"), isOn: $model.draft.advanced.ignoreSslErrors)
                        .help("""
                            Affects certificate validation and non-torrent protocol activities \
                            (e.g. RSS feeds, program updates, torrent files, geoip db, etc)
                            """)
                    if let help = SettingsCatalog.help("ignore_ssl_errors") {
                        SettingFootnote(text: help, style: model.draft.advanced.ignoreSslErrors ? .warning : .secondary)
                    }
                }
                .setting("ignore_ssl_errors", help: false)
            }
        }
        .task(id: model.draft.advanced.currentNetworkInterface) {
            await network.load(client: model.appInfo, interface: model.draft.advanced.currentNetworkInterface)
        }
    }
}
