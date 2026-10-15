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
                }.settingAnchor("behavior.17")
                Picker("Color scheme:", selection: $gui.colorScheme) {
                    ForEach([ColorSchemePreference.dark, .light, .system]) { scheme in
                        Text(scheme.title).tag(scheme)
                    }
                }.settingAnchor("behavior.18")
            } header: {
                Text("Interface")
            } footer: {
                Text("Changing Interface settings requires application restart")
                    .settingsFootnote()
            }

            Section("Transfer List") {
                Toggle("Confirm when deleting torrents", isOn: $model.draft.behavior.confirmTorrentDeletion).settingAnchor("behavior.20")
                    .help("Shows a confirmation dialog upon torrent deletion")
                Toggle("Use alternating row colors", isOn: $gui.alternatingRowColors).settingAnchor("behavior.21")
                Toggle("Use different text colors by torrent states", isOn: $gui.useTorrentStatesColors).settingAnchor("behavior.22")
                Toggle("Make progress bars follow text colors", isOn: $gui.progressBarFollowsTextColor).settingAnchor("behavior.23")
                    .disabled(!gui.useTorrentStatesColors)
                LabeledContent {
                    Picker("Hide zero and infinity values", selection: $gui.hideZeroMode) {
                        ForEach(HideZeroMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }.settingAnchor("behavior.24")
                    .labelsHidden()
                    .fixedSize()
                    .disabled(!gui.hideZeroValues)
                } label: {
                    Toggle("Hide zero and infinity values", isOn: $gui.hideZeroValues).settingAnchor("behavior.25")
                }
                Toggle("Auto hide zero status filters", isOn: $gui.hideZeroStatusFilters).settingAnchor("behavior.26")
                Toggle("Use separate \"Tracker status\" filter", isOn: $gui.separateTrackerStatusFilter)
                    .help("Use separate \"Tracker status\" filter. Otherwise it gets merged with \"Trackers\" filter.")
            }.settingAnchor("behavior.19")

            Section("Action on double-click") {
                Picker("Downloading torrents:", selection: $gui.doubleClickDownloading) {
                    ForEach(DoubleClickAction.menuOrder) { action in
                        Text(action.title).tag(action)
                    }
                }.settingAnchor("behavior.28")
                Picker("Completed torrents:", selection: $gui.doubleClickCompleted) {
                    ForEach(DoubleClickAction.menuOrder) { action in
                        Text(action.title).tag(action)
                    }
                }.settingAnchor("behavior.29")
            }.settingAnchor("behavior.27")

            Section("Torrent Content View") {
                Toggle("Drag content from qBittorrent Neo", isOn: $gui.torrentContentDragEnabled).settingAnchor("behavior.31")
                    .help("Replaces multi-selection (hold Option key to invert)")
            }.settingAnchor("behavior.30")

            BehaviorDesktopSection(gui: gui, desktop: desktop)

            Section("Power Management") {
                Toggle("Inhibit system sleep when torrents are downloading", isOn: $gui.preventSuspendWhenDownloading).settingAnchor("behavior.33")
                Toggle("Inhibit system sleep when torrents are seeding", isOn: $gui.preventSuspendWhenSeeding).settingAnchor("behavior.34")
            }.settingAnchor("behavior.32")

            BehaviorLogFilesSection(model: model)

            Section {
                Toggle("Show free disk space in status bar", isOn: $gui.statusBarFreeDiskSpace).settingAnchor("behavior.35")
                Toggle("Show external IP in status bar", isOn: $model.draft.behavior.statusBarExternalIp).settingAnchor("behavior.36")
                Toggle("Log performance warnings", isOn: $model.draft.behavior.performanceWarning).settingAnchor("behavior.37")
            }
        }
        .task { desktop.refresh() }
    }
}
