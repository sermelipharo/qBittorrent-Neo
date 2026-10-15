import SwiftUI

/// Privacy › I2P (experimental, advanced), with the tunnel settings in a disclosure.
struct I2PGroup: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        SettingsGroup(.i2p) {
            Toggle(SettingsCatalog.title("i2p_enabled"), isOn: $model.draft.connection.i2pEnabled)
                .setting("i2p_enabled")
        } content: {
            Group {
                CommitTextField(title: SettingsCatalog.key("i2p_address"), text: $model.draft.connection.i2pAddress, trims: true)
                    .setting("i2p_address")
                SpinField(title: SettingsCatalog.key("i2p_port"), value: $model.draft.connection.i2pPort, range: 1...65_535)
                    .setting("i2p_port")
                Toggle(SettingsCatalog.title("i2p_mixed_mode"), isOn: $model.draft.connection.i2pMixedMode)
                    .help("""
                        If "mixed mode" is enabled I2P torrents are allowed to also get peers from other sources than \
                        the tracker, and connect to regular IPs, not providing any anonymization. This may be useful \
                        if the user is not interested in the anonymization of I2P, but still wants to be able to \
                        connect to I2P peers.
                        """)
                    .setting("i2p_mixed_mode")
                SettingsDisclosure(title: "Tunnel settings", section: .i2p) {
                    SpinField(title: SettingsCatalog.key("i2p_inbound_quantity"), value: $model.draft.connection.i2pInboundQuantity, range: 1...16)
                        .setting("i2p_inbound_quantity")
                    SpinField(title: SettingsCatalog.key("i2p_outbound_quantity"), value: $model.draft.connection.i2pOutboundQuantity, range: 1...16)
                        .setting("i2p_outbound_quantity")
                    SpinField(title: SettingsCatalog.key("i2p_inbound_length"), value: $model.draft.connection.i2pInboundLength, range: 0...7)
                        .setting("i2p_inbound_length")
                    SpinField(title: SettingsCatalog.key("i2p_outbound_length"), value: $model.draft.connection.i2pOutboundLength, range: 0...7)
                        .setting("i2p_outbound_length")
                }
            }
            .disabled(!model.draft.connection.i2pEnabled)
        }
    }
}
