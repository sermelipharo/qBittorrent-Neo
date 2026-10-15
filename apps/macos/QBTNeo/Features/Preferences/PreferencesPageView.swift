import SwiftUI

/// The form of one Settings page, with the apply error (if any) below it.
struct PreferencesPageView: View {
    let page: PreferencesPage
    let model: PreferencesModel
    /// Setting to scroll to and highlight (from the Settings search).
    var target: SettingTarget?

    @State private var highlighted: String?

    var body: some View {
        ScrollViewReader { proxy in
            content
                .formStyle(.grouped)
                .environment(\.highlightedSetting, highlighted)
                .disabled(!model.isLoaded)
                .task(id: target) { await reveal(target, with: proxy) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let error = model.applyError {
                InlineMessage(text: String(localized: "Couldn't save the settings: \(error)"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Design.Spacing.medium)
                    .background(.bar)
            }
        }
    }

    private func reveal(_ target: SettingTarget?, with proxy: ScrollViewProxy) async {
        guard let target, target.page == page else { return }
        try? await Task.sleep(for: .milliseconds(150))
        withAnimation { proxy.scrollTo(target.anchor, anchor: .center) }
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation { highlighted = target.anchor }
        try? await Task.sleep(for: .seconds(1.6))
        withAnimation { highlighted = nil }
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
