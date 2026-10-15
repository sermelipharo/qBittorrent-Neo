import SwiftUI

/// The content of one properties tab for the current torrent.
struct PropertiesPage: View {
    let tab: PropertiesTab
    @Environment(AppModel.self) private var model

    var body: some View {
        Group {
            if tab == .speed {
                SpeedTab()
            } else if let item = model.list.currentItem {
                switch tab {
                case .general: GeneralTab(item: item)
                case .trackers: TrackersTab(item: item)
                case .peers: PeersTab(item: item)
                case .httpSources: HTTPSourcesTab(item: item)
                case .content: ContentTab(item: item)
                case .speed: EmptyView()
                }
            } else {
                ContentUnavailableView("No Torrent Selected", systemImage: "cursorarrow.click.2",
                                       description: Text("Select a torrent to see its \(tab.title.lowercased()) details."))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
