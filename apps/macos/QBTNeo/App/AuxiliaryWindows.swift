import SwiftUI

/// Windows owned by other features (RSS, Search, Log, Creator, Statistics,
/// Cookies, About). Each currently shows `PlaceholderWindowView`; replace the
/// content view when the feature lands, keeping the scene identifiers.
struct AuxiliaryWindows: Scene {
    let model: AppModel

    var body: some Scene {
        Window(AppWindowID.rss.title, id: AppWindowID.rss.rawValue) {
            RSSWindow().lockGated().environment(model).environment(model.gui)
        }
        .defaultSize(width: 980, height: 640)

        Window(AppWindowID.search.title, id: AppWindowID.search.rawValue) {
            SearchWindow().lockGated().environment(model).environment(model.gui)
        }
        .defaultSize(width: 980, height: 640)

        Window(AppWindowID.log.title, id: AppWindowID.log.rawValue) {
            ExecutionLogWindow().lockGated().environment(model).environment(model.gui)
        }
        .defaultSize(width: 860, height: 520)
        .keyboardShortcut("l", modifiers: [.command, .option])

        Window(AppWindowID.creator.title, id: AppWindowID.creator.rawValue) {
            TorrentCreatorWindow().lockGated().environment(model)
        }
        .defaultSize(width: 620, height: 700)

        Window(AppWindowID.statistics.title, id: AppWindowID.statistics.rawValue) {
            StatisticsWindow().lockGated().environment(model)
        }
        .defaultSize(width: 420, height: 620)

        Window(AppWindowID.cookies.title, id: AppWindowID.cookies.rawValue) {
            CookiesWindow().lockGated().environment(model)
        }
        .defaultSize(width: 720, height: 420)

        Window(FeatureWindowID.rssDownloader.title, id: FeatureWindowID.rssDownloader.rawValue) {
            RSSDownloaderWindow().lockGated().environment(model).environment(model.gui)
        }
        .defaultSize(width: 1_180, height: 720)

        Window(FeatureWindowID.searchPlugins.title, id: FeatureWindowID.searchPlugins.rawValue) {
            SearchPluginsWindow().lockGated().environment(model)
        }
        .defaultSize(width: 720, height: 460)

        Window(AppWindowID.about.title, id: AppWindowID.about.rawValue) {
            AboutWindow().lockGated().environment(model)
        }
        .windowResizability(.contentSize)
    }
}
