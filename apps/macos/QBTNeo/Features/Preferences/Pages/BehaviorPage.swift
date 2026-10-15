import SwiftUI

/// Settings › Behavior (preferences.md §1).
struct BehaviorPage: View {
    @Bindable var model: PreferencesModel
    @Environment(GUIPreferences.self) private var gui
    @State private var desktop = DesktopIntegrationModel()

    var body: some View {
        @Bindable var gui = gui
        Form {
            Section {
                Picker("Language:", selection: $model.draft.behavior.locale) {
                    ForEach(LanguageChoice.choices(including: model.draft.behavior.locale)) { choice in
                        Text(choice.title).tag(choice.code)
                    }
                }
                Picker("Color scheme:", selection: $gui.colorScheme) {
                    ForEach([ColorSchemePreference.dark, .light, .system]) { scheme in
                        Text(scheme.title).tag(scheme)
                    }
                }
            } header: {
                Text("Interface")
            } footer: {
                Text("Changing Interface settings requires application restart")
                    .settingsFootnote()
            }

            Section("Transfer List") {
                Toggle("Confirm when deleting torrents", isOn: $model.draft.behavior.confirmTorrentDeletion)
                    .help("Shows a confirmation dialog upon torrent deletion")
                Toggle("Use alternating row colors", isOn: $gui.alternatingRowColors)
                Toggle("Use different text colors by torrent states", isOn: $gui.useTorrentStatesColors)
                Toggle("Make progress bars follow text colors", isOn: $gui.progressBarFollowsTextColor)
                    .disabled(!gui.useTorrentStatesColors)
                LabeledContent {
                    Picker("Hide zero and infinity values", selection: $gui.hideZeroMode) {
                        ForEach(HideZeroMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .disabled(!gui.hideZeroValues)
                } label: {
                    Toggle("Hide zero and infinity values", isOn: $gui.hideZeroValues)
                }
                Toggle("Auto hide zero status filters", isOn: $gui.hideZeroStatusFilters)
                Toggle("Use separate \"Tracker status\" filter", isOn: $gui.separateTrackerStatusFilter)
                    .help("Use separate \"Tracker status\" filter. Otherwise it gets merged with \"Trackers\" filter.")
            }

            Section("Action on double-click") {
                Picker("Downloading torrents:", selection: $gui.doubleClickDownloading) {
                    ForEach(DoubleClickAction.menuOrder) { action in
                        Text(action.title).tag(action)
                    }
                }
                Picker("Completed torrents:", selection: $gui.doubleClickCompleted) {
                    ForEach(DoubleClickAction.menuOrder) { action in
                        Text(action.title).tag(action)
                    }
                }
            }

            Section("Torrent Content View") {
                Toggle("Drag content from qBittorrent Neo", isOn: $gui.torrentContentDragEnabled)
                    .help("Replaces multi-selection (hold Option key to invert)")
            }

            BehaviorDesktopSection(gui: gui, desktop: desktop)

            Section("Power Management") {
                Toggle("Inhibit system sleep when torrents are downloading", isOn: $gui.preventSuspendWhenDownloading)
                Toggle("Inhibit system sleep when torrents are seeding", isOn: $gui.preventSuspendWhenSeeding)
            }

            BehaviorLogFilesSection(model: model)

            Section {
                Toggle("Show free disk space in status bar", isOn: $gui.statusBarFreeDiskSpace)
                Toggle("Show external IP in status bar", isOn: $model.draft.behavior.statusBarExternalIp)
                Toggle("Log performance warnings", isOn: $model.draft.behavior.performanceWarning)
            }
        }
        .task { desktop.refresh() }
    }
}
