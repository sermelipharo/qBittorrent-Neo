import SwiftUI

/// Settings › RSS (preferences.md §7).
struct RSSSettingsPage: View {
    @Bindable var model: PreferencesModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Form {
            Section("RSS Reader") {
                Toggle("Enable fetching RSS feeds", isOn: $model.draft.rss.rssProcessingEnabled)
                SpinField(title: "Feeds refresh interval:", value: $model.draft.rss.rssRefreshInterval,
                          range: 1...999_999, unit: String(localized: "min"))
                SpinField(title: "Same host request delay:", value: $model.draft.rss.rssFetchDelay,
                          range: 0...2_147_483_646, unit: String(localized: "sec"), width: FeatureDesign.Width.wideSpinField)
                SpinField(title: "Maximum number of articles per feed:", value: $model.draft.rss.rssMaxArticlesPerFeed,
                          range: 0...2_147_483_646, width: FeatureDesign.Width.wideSpinField)
            }
            Section("RSS Torrent Auto Downloader") {
                Toggle("Enable auto downloading of RSS torrents", isOn: $model.draft.rss.rssAutoDownloadingEnabled)
                LabeledContent {
                    Button("Edit auto downloading rules…") { openWindow(id: FeatureWindowID.rssDownloader.rawValue) }
                } label: {
                    EmptyView()
                }
            }
            Section {
                Toggle("Download REPACK/PROPER episodes", isOn: $model.draft.rss.rssDownloadRepackProperEpisodes)
                LabeledContent("Filters:") {
                    CommitTextEditor(title: "Filters:", text: $model.smartEpisodeFiltersText, minHeight: 90)
                }
            } header: {
                Text("RSS Smart Episode Filter")
            } footer: {
                Text("One regular expression per line; together they extract the episode number (S01E01, 1x1, 2017.12.31, 31.12.2017).")
                    .settingsFootnote()
            }
        }
    }
}
