import SwiftUI

/// The About window (features.md §3.16): version header and tabs with the
/// project description, authors, licenses and build information.
struct AboutWindow: View {
    @Environment(AppModel.self) private var app
    @State private var tab: AboutTab
    @State private var buildInfo: BuildInfo?

    init(initialTab: AboutTab = .about) {
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: Design.Spacing.large) {
            AboutHeader(version: buildInfo.map { "v\($0.app)" } ?? "", bitness: buildInfo?.bitness ?? 64)
            TabView(selection: $tab) {
                Tab(AboutTab.about.title, systemImage: Symbol.infoCircle, value: AboutTab.about) {
                    AboutOverviewTab()
                }
                Tab(AboutTab.credits.title, systemImage: Symbol.person2, value: AboutTab.credits) {
                    AboutCreditsTab()
                }
                Tab(AboutTab.license.title, systemImage: Symbol.docText, value: AboutTab.license) {
                    AboutLicenseTab()
                }
                Tab(AboutTab.software.title, systemImage: Symbol.shippingbox, value: AboutTab.software) {
                    AboutSoftwareTab(info: buildInfo)
                }
            }
        }
        .padding(Design.Spacing.xLarge)
        .frame(width: FeatureDesign.Window.aboutSize.width, height: FeatureDesign.Window.aboutSize.height)
        .navigationTitle(AppWindowID.about.title)
        .task(id: app.phase) {
            guard let client = app.client else { return }
            buildInfo = await CoreCall.run { client.buildInfo() }
        }
    }
}
