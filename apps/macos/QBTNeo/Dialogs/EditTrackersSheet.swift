import SwiftUI

/// "Edit trackers" (features.md §3.11): the trackers common to every selected
/// torrent, grouped into tiers; OK replaces each torrent's tracker list.
struct EditTrackersSheet: View {
    let ids: [String]
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        DialogContainer(title: "Edit trackers", width: Design.Window.wideDialogWidth, onConfirm: save) {
            Text("""
            One tracker URL per line.

            - You can split the trackers into groups by inserting blank lines.
            - All trackers within the same group will belong to the same tier.
            - The group on top will be tier 0, the next group tier 1 and so on.
            - Below will show the common subset of trackers of the selected torrents.
            """)
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            TrackerListEditor(text: $text, minHeight: 220)
        }
        .task { text = await model.commonTrackersText(ids) }
    }

    private func save() {
        let entries = TrackerTierParser.parse(text)
        model.perform { client in
            for id in ids { try client.replaceTrackers(hash: id, trackers: entries) }
        }
        dismiss()
    }
}
