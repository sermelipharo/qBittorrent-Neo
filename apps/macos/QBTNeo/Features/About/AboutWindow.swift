import SwiftUI

/// The About window (features.md §3.16): version header and tabs with the
/// project description, authors, licenses and build information.
struct AboutWindow: View {
    @Environment(AppModel.self) private var app
    @State private var tab = AboutTab.about
    @State private var buildInfo: BuildInfo?

    var body: some View {
        VStack(spacing: Design.Spacing.large) {
            AboutHeader(version: buildInfo.map { "v\($0.app)" } ?? "", bitness: buildInfo?.bitness ?? 64)
            TabView(selection: $tab) {
                Tab(AboutTab.about.title, systemImage: "info.circle", value: AboutTab.about) {
                    AboutOverviewTab()
                }
                Tab(AboutTab.authors.title, systemImage: "person.2", value: AboutTab.authors) {
                    AboutAuthorsTab()
                }
                Tab(AboutTab.license.title, systemImage: "doc.text", value: AboutTab.license) {
                    AboutLicenseTab()
                }
                Tab(AboutTab.software.title, systemImage: "shippingbox", value: AboutTab.software) {
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
