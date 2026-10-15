import SwiftUI

/// "Global Speed Limits" (features.md §3.8): normal and alternative limits.
struct SpeedLimitsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var limits = Limits()
    @State private var original = Limits()

    struct Limits: Equatable {
        var upload: Int64 = 0
        var download: Int64 = 0
        var altUpload: Int64 = 0
        var altDownload: Int64 = 0
    }

    var body: some View {
        DialogContainer(title: "Global Speed Limits", width: Design.Window.wideDialogWidth, onConfirm: save) {
            Form {
                Section {
                    SpeedLimitField(title: "Upload:", limit: $limits.upload, showsSlider: true)
                    SpeedLimitField(title: "Download:", limit: $limits.download, showsSlider: true)
                } header: {
                    Label("Speed limits", systemImage: "speedometer")
                }
                Section {
                    SpeedLimitField(title: "Upload:", limit: $limits.altUpload, showsSlider: true)
                    SpeedLimitField(title: "Download:", limit: $limits.altDownload, showsSlider: true)
                } header: {
                    Label("Alternative speed limits", systemImage: "tortoise")
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear(perform: load)
    }

    private func load() {
        let speed = model.corePreferences.speed
        limits = Limits(upload: speed.upLimit, download: speed.dlLimit, altUpload: speed.altUpLimit, altDownload: speed.altDlLimit)
        original = limits
    }

    /// Writes back only the changed values.
    private func save() {
        if limits != original {
            var prefs = model.corePreferences
            prefs.speed.upLimit = limits.upload
            prefs.speed.dlLimit = limits.download
            prefs.speed.altUpLimit = limits.altUpload
            prefs.speed.altDlLimit = limits.altDownload
            model.savePreferences(prefs)
            model.refreshSoon()
        }
        dismiss()
    }
}
