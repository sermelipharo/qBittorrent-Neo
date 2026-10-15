import SwiftUI

/// Up/down buttons beside the tracker list: tier − 1 / tier + 1 for the
/// selected trackers (the only tier-editing UI, like qBittorrent).
struct TrackerTierButtons: View {
    let item: TorrentItem
    @Environment(AppModel.self) private var model

    var body: some View {
        let hasSelection = !model.selectedTrackerURLs().isEmpty
        VStack(spacing: Design.Spacing.small) {
            Spacer()
            Button("Move Up", systemImage: "chevron.up") { model.shiftTrackerTiers(hash: item.id, by: -1) }
                .help("Decrease the tier of the selected trackers")
            Button("Move Down", systemImage: "chevron.down") { model.shiftTrackerTiers(hash: item.id, by: 1) }
                .help("Increase the tier of the selected trackers")
            Spacer()
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .disabled(!hasSelection)
        .padding(.horizontal, Design.Spacing.small)
    }
}
