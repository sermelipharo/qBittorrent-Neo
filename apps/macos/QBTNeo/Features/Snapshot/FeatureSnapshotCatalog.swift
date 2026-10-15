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

    private static let paletteSize = CGSize(width: 1_100, height: 680)

    static var entries: [Entry] {
        [
            Entry(name: "sidebar", title: "Sidebar", size: CGSize(width: 260, height: 760)) { _ in
                AnyView(SidebarView().environment(\.isSnapshotRendering, true))
            },
            Entry(name: "menubar", title: "Menu bar item", size: CGSize(width: 420, height: 320)) { _ in
                AnyView(MenuBarSnapshotView())
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
            Entry(name: "about-credits", title: AppWindowID.about.title, size: FeatureDesign.Window.aboutSize) { _ in
                AnyView(AboutWindow(initialTab: .credits))
            },
            Entry(name: "about-credits", title: AppWindowID.about.title, size: FeatureDesign.Window.aboutSize) { _ in
                AnyView(AboutWindow(initialTab: .credits))
            },
            Entry(name: "about", title: AppWindowID.about.title, size: FeatureDesign.Window.aboutSize) { _ in
                AnyView(AboutWindow())
            },
            Entry(name: "cookies", title: AppWindowID.cookies.title, size: CGSize(width: 760, height: 420)) { _ in
                AnyView(CookiesWindow())
            },
            Entry(name: "palette-empty", title: AppWindowID.main.title, size: paletteSize) { model in
                AnyView(PaletteSnapshot(model: model, query: ""))
            },
            Entry(name: "palette-query", title: AppWindowID.main.title, size: paletteSize) { model in
                AnyView(PaletteSnapshot(model: model, query: PaletteSnapshot.sampleQuery))
            },
            Entry(name: "palette-torrent", title: AppWindowID.main.title, size: paletteSize) { model in
                AnyView(PaletteSnapshot(model: model, query: "sintel", drillIn: true))
            },
        ]
    }
}
