import SwiftUI

/// Transfers › Adding › Extra Trackers (advanced): trackers appended to every new download.
struct ExtraTrackersGroup: View {
    @Bindable var model: PreferencesModel

    var body: some View {
        let bittorrent = model.draft.bittorrent
        SettingsGroup(.extraTrackers) {
            Toggle(SettingsCatalog.title("add_trackers_enabled"), isOn: $model.draft.bittorrent.addTrackersEnabled)
                .setting("add_trackers_enabled")
        } content: {
            CommitTextEditor(title: SettingsCatalog.key("add_trackers_enabled"), text: $model.draft.bittorrent.addTrackers,
                             minHeight: 72, prompt: String(localized: "One URL per line; an empty line starts a new tier."))
                .labelsHidden()
                .disabled(!bittorrent.addTrackersEnabled)
            Toggle(SettingsCatalog.title("add_trackers_from_url_enabled"), isOn: $model.draft.bittorrent.addTrackersFromUrlEnabled)
                .setting("add_trackers_from_url_enabled")
            Group {
                CommitTextField(title: "URL:", text: $model.draft.bittorrent.addTrackersUrl, prompt: "https://example.org/trackers.txt", trims: true)
                LabeledContent("Fetched trackers") {
                    ScrollView {
                        Text(bittorrent.addTrackersUrlList.isEmpty ? String(localized: "None") : bittorrent.addTrackersUrlList)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 72)
                }
            }
            .disabled(!bittorrent.addTrackersFromUrlEnabled)
        }
    }
}
