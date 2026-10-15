import SwiftUI

/// The feature windows rendered in snapshot mode, with their sizes.
@MainActor
enum FeatureSnapshotCatalog {
    struct Entry {
        let name: String
        let title: String
        let size: CGSize
        let view: @MainActor (AppModel) -> AnyView
    }

    static var entries: [Entry] {
        preferencePages + [
            Entry(name: "settingssearch", title: "Settings", size: CGSize(width: 900, height: 700)) { _ in
                let query = ProcessInfo.processInfo.environment["QBT_SETTINGS_QUERY"] ?? "proxy"
                return AnyView(PreferencesWindow(initialQuery: query))
            },
            Entry(name: "sidebar", title: "Sidebar", size: CGSize(width: 260, height: 760)) { _ in
                AnyView(SidebarView().environment(\.isSnapshotRendering, true))
            },
            Entry(name: "creator", title: AppWindowID.creator.title, size: CGSize(width: 640, height: 940)) { _ in
                AnyView(TorrentCreatorWindow())
            },
            Entry(name: "search", title: AppWindowID.search.title, size: CGSize(width: 1_180, height: 640)) { _ in
                AnyView(SearchWindow(initialPattern: "night of the living dead"))
            },
            Entry(name: "searchplugins", title: FeatureWindowID.searchPlugins.title, size: CGSize(width: 720, height: 460)) { _ in
                AnyView(SearchPluginsWindow())
            },
            Entry(name: "rssdownloader", title: FeatureWindowID.rssDownloader.title, size: CGSize(width: 1_200, height: 900)) { _ in
                AnyView(RSSDownloaderWindow())
            },
            Entry(name: "rss", title: AppWindowID.rss.title, size: CGSize(width: 1_180, height: 680)) { _ in
                AnyView(RSSWindow(initialSelection: "Podcasts & Video\\Blender Studio"))
            },
            Entry(name: "statistics", title: AppWindowID.statistics.title, size: CGSize(width: 420, height: 620)) { _ in
                AnyView(StatisticsWindow())
            },
            Entry(name: "log", title: AppWindowID.log.title, size: CGSize(width: 860, height: 520)) { _ in
                AnyView(ExecutionLogWindow())
            },
            Entry(name: "about", title: AppWindowID.about.title, size: FeatureDesign.Window.aboutSize) { _ in
                AnyView(AboutWindow())
            },
            Entry(name: "cookies", title: AppWindowID.cookies.title, size: CGSize(width: 760, height: 420)) { _ in
                AnyView(CookiesWindow())
            },
        ]
    }

    private static var preferencePages: [Entry] {
        PreferencesPage.allCases.map { page in
            let height = page == .advanced ? 2_900.0 : (page == .behavior || page == .downloads || page == .webUI ? 1_900 : 1_200)
            return Entry(name: "settings-\(page.title.lowercased())", title: page.title, size: CGSize(width: 900, height: height)) { _ in
                AnyView(PreferencesWindow(pinnedPage: page))
            }
        }
    }
}
