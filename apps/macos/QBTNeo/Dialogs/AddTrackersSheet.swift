import SwiftUI

/// "Add trackers" (features.md §3.12): new tiers follow the last existing tier.
struct AddTrackersSheet: View {
    let id: String
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        @Bindable var gui = gui
        DialogContainer(title: "Add trackers", confirmTitle: "Add", width: Design.Window.wideDialogWidth, onConfirm: save) {
            Text("List of trackers to add (one per line):")
            TrackerListEditor(text: $text, minHeight: 200)
            LabeledContent("µTorrent compatible list URL:") {
                TextField("List URL", text: $gui.trackersListURL, prompt: Text("https://"))
                    .labelsHidden()
            }
        }
    }

    private func save() {
        let lastTier = model.properties.trackerEntries.filter { $0.tier >= 0 }.map(\.tier).max()
        let entries = TrackerTierParser.parse(text, baseTier: lastTier.map { $0 + 1 } ?? 0)
        if !entries.isEmpty {
            model.perform { try $0.addTrackers(hash: id, trackers: entries) }
        }
        dismiss()
    }
}
