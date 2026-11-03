import SwiftUI

/// Transfers › Search & RSS: the two optional modules.
struct TransfersSearchRSSSegment: View {
    @Bindable var model: PreferencesModel
    @Environment(AppModel.self) private var app
    @Environment(GUIPreferences.self) private var gui
    @Environment(\.openWindow) private var openWindow
    @AppStorage(FeatureDefaults.searchHistoryLength, store: AppDefaults.store) private var historyLength = 50
    @State private var status: SearchEngineStatus?

    var body: some View {
        @Bindable var gui = gui
        Group {
            SettingsGroup(.search) {
                Toggle(SettingsCatalog.title("Preferences/Search/SearchEnabled"), isOn: $gui.searchEnabled)
                    .setting("Preferences/Search/SearchEnabled")
            } content: {
                VStack(alignment: .leading, spacing: Design.Spacing.small) {
                    HStack(spacing: Design.Spacing.regular) {
                        Button(SettingsCatalog.title("system.searchPlugins")) { openWindow(id: FeatureWindowID.searchPlugins.rawValue) }
                        if let status, status.pythonFound {
                            Text("Python \(status.pythonVersion)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .help(status.pythonPath)
                        }
                    }
                    if let status, !status.pythonFound {
                        PythonProblemRow(status: status, usesCustomPath: !model.draft.advanced.pythonExecutablePath.isEmpty) {
                            Task { await model.applyImmediately { $0.advanced.pythonExecutablePath = "" } }
                        }
                    }
                }
                .setting("system.searchPlugins")
                Toggle(SettingsCatalog.title("store_search_jobs"), isOn: $model.draft.behavior.storeSearchJobs)
                    .setting("store_search_jobs")
                Toggle(SettingsCatalog.title("store_search_job_results"), isOn: $model.draft.behavior.storeSearchJobResults)
                    .disabled(!model.draft.behavior.storeSearchJobs)
                    .setting("store_search_job_results", indented: true)
                Toggle(SettingsCatalog.title("Search/CloseSearchTabWithMiddleClick"), isOn: $gui.closeSearchTabWithMiddleClick)
                    .setting("Search/CloseSearchTabWithMiddleClick")
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
                PythonPathField(path: $model.draft.advanced.pythonExecutablePath)
                    .onChange(of: model.draft.advanced.pythonExecutablePath) { _, path in
                        // A path pasted in quotes (qBittorrent 5.3 refuses those) works without them.
                        for quote in ["\"", "'"] where path.count > 1 && path.hasPrefix(quote) && path.hasSuffix(quote) {
                            model.draft.advanced.pythonExecutablePath = String(path.dropFirst().dropLast())
                        }
                    }
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
                Toggle(SettingsCatalog.title("rss_auto_downloading_enabled"), isOn: $model.draft.rss.rssAutoDownloadingEnabled)
                    .setting("rss_auto_downloading_enabled")
                Button("Edit auto downloading rules…") { openWindow(id: FeatureWindowID.rssDownloader.rawValue) }
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
            await refreshStatus()
            // The core re-detects Python when the path changes and reports it
            // with the plugins event.
            for await event in app.events() {
                if case .searchPluginsUpdated = event { await refreshStatus() }
            }
        }
        .task(id: model.draft.advanced.pythonExecutablePath) {
            // A changed path: check again once it is applied and Python is re-detected.
            guard status != nil else { return }
            try? await Task.sleep(for: .seconds(1.5))
            await refreshStatus()
        }
    }

    private func refreshStatus() async {
        guard let client = app.client as? any SearchClient else { return }
        status = await CoreCall.run { client.searchEngineStatus() }
    }
}
