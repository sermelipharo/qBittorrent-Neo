import SwiftUI

/// The view of one pane, by pane.
struct SettingsPaneContent: View {
    let pane: SettingsPane
    let model: PreferencesModel

    var body: some View {
        switch pane {
        case .general: GeneralPane(model: model)
        case .interface: InterfacePane(model: model)
        case .transfers: TransfersPane(model: model)
        case .speed: SpeedPane(model: model)
        case .network: NetworkPane(model: model)
        case .privacy: PrivacyPane(model: model)
        case .remote: RemotePane(model: model)
        case .advanced: AdvancedPane(model: model)
        }
    }
}
