import SwiftUI

/// The form of one Settings page, with the apply error (if any) below it.
struct PreferencesPageView: View {
    let page: PreferencesPage
    let model: PreferencesModel

    var body: some View {
        content
            .formStyle(.grouped)
            .disabled(!model.isLoaded)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let error = model.applyError {
                    InlineMessage(text: String(localized: "Couldn't save the settings: \(error)"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(Design.Spacing.medium)
                        .background(.bar)
                }
            }
    }

    @ViewBuilder private var content: some View {
        switch page {
        case .behavior: BehaviorPage(model: model)
        case .downloads: DownloadsPage(model: model)
        case .connection: ConnectionPage(model: model)
        case .speed: SpeedPage(model: model)
        case .bittorrent: BitTorrentPage(model: model)
        case .search: SearchSettingsPage()
        case .rss: RSSSettingsPage(model: model)
        case .webUI: WebUIPage(model: model)
        case .advanced: AdvancedPage(model: model)
        }
    }
}
