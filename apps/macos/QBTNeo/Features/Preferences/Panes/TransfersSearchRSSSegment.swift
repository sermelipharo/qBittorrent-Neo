import SwiftUI

/// Transfers › Search & RSS: the two optional modules.
struct TransfersSearchRSSSegment: View {
    @Bindable var model: PreferencesModel
    @Environment(AppModel.self) private var app
    @Environment(GUIPreferences.self) private var gui
    @Environment(\.openWindow) private var openWindow
    @AppStorage(FeatureDefaults.storeSearchTabs) private var storeTabs = false
    @AppStorage(FeatureDefaults.storeSearchResults) private var storeResults = false
    @AppStorage(FeatureDefaults.searchHistoryLength) private var historyLength = 50
    @State private var status: SearchEngineStatus?

    var body: some View {
        @Bindable var gui = gui
        Group {
            SettingsGroup(.search) {
                Toggle(SettingsCatalog.title("Preferences/Search/SearchEnabled"), isOn: $gui.searchEnabled)
                    .setting("Preferences/Search/SearchEnabled")
            } content: {
                HStack(spacing: Design.Spacing.regular) {
                    Button(SettingsCatalog.title("system.searchPlugins")) { openWindow(id: FeatureWindowID.searchPlugins.rawValue) }
                    pythonStatus
                }
                .setting("system.searchPlugins")
                Toggle(SettingsCatalog.title("Search/StoreOpenedSearchTabs"), isOn: $storeTabs)
                    .setting("Search/StoreOpenedSearchTabs")
                Toggle(SettingsCatalog.title("Search/StoreOpenedSearchTabResults"), isOn: $storeResults)
                    .disabled(!storeTabs)
                    .setting("Search/StoreOpenedSearchTabResults", indented: true)
                LabeledContent(SettingsCatalog.key("Search/HistoryLength")) {
                    HStack(spacing: Design.Spacing.tight) {
                        TextField(SettingsCatalog.title("Search/HistoryLength"), value: $historyLength, format: .number)
                            .labelsHidden()
                            .multilineTextAlignment(.trailing)
                            .frame(width: FeatureDesign.Width.narrowField)
                        Stepper(SettingsCatalog.title("Search/HistoryLength"), value: $historyLength, in: 0...99)
                            .labelsHidden()
                    }
                }
                .onChange(of: historyLength) { historyLength = min(max(historyLength, 0), 99) }
                .setting("Search/HistoryLength")
                CommitTextField(title: SettingsCatalog.key("python_executable_path"), text: $model.draft.advanced.pythonExecutablePath,
                                prompt: String(localized: "(Auto detect if empty)"), trims: true)
                    .setting("python_executable_path")
            }

            SettingsGroup(.rss) {
                Toggle(SettingsCatalog.title("GUI/RSSWidget/Enabled"), isOn: $gui.rssEnabled)
                    .setting("GUI/RSSWidget/Enabled")
            } content: {
                Toggle(SettingsCatalog.title("rss_processing_enabled"), isOn: $model.draft.rss.rssProcessingEnabled)
                    .setting("rss_processing_enabled")
                Group {
                    SpinField(title: SettingsCatalog.key("rss_refresh_interval"), value: $model.draft.rss.rssRefreshInterval,
                              range: 1...999_999, unit: String(localized: "min"))
                        .setting("rss_refresh_interval")
                    SpinField(title: SettingsCatalog.key("rss_fetch_delay"), value: $model.draft.rss.rssFetchDelay,
                              range: 0...2_147_483_646, unit: String(localized: "sec"), width: FeatureDesign.Width.wideSpinField)
                        .setting("rss_fetch_delay")
                    SpinField(title: SettingsCatalog.key("rss_max_articles_per_feed"), value: $model.draft.rss.rssMaxArticlesPerFeed,
                              range: 0...2_147_483_646, width: FeatureDesign.Width.wideSpinField)
                        .setting("rss_max_articles_per_feed")
                }
                .disabled(!model.draft.rss.rssProcessingEnabled)
                HStack(spacing: Design.Spacing.regular) {
                    Toggle(SettingsCatalog.title("rss_auto_downloading_enabled"), isOn: $model.draft.rss.rssAutoDownloadingEnabled)
                    Button("Edit auto downloading rules…") { openWindow(id: FeatureWindowID.rssDownloader.rawValue) }
                }
                .setting("rss_auto_downloading_enabled")
            }

            SettingsGroup(.smartEpisodeFilter) {
                Toggle(SettingsCatalog.title("rss_download_repack_proper_episodes"), isOn: $model.draft.rss.rssDownloadRepackProperEpisodes)
                    .setting("rss_download_repack_proper_episodes")
            } content: {
                VStack(alignment: .leading, spacing: SettingsLayout.footnoteSpacing) {
                    CommitTextEditor(title: SettingsCatalog.key("rss_smart_episode_filters"), text: $model.smartEpisodeFiltersText, minHeight: 72)
                        .labelsHidden()
                    SettingFootnote(text: String(localized: """
                        One regular expression per line; together they extract the episode number (S01E01, 1x1, 2017.12.31, 31.12.2017).
                        """))
                }
                .setting("rss_smart_episode_filters")
            }
        }
        .task(id: app.phase) {
            guard let client = app.client as? any SearchClient else { return }
            status = await CoreCall.run { client.searchEngineStatus() }
        }
    }

    @ViewBuilder private var pythonStatus: some View {
        if let status {
            Text(status.pythonFound ? "Python \(status.pythonVersion)" : status.message)
                .font(.callout)
                .foregroundStyle(status.pythonFound ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.red))
                .lineLimit(1)
                .help(status.pythonPath)
        }
    }
}
