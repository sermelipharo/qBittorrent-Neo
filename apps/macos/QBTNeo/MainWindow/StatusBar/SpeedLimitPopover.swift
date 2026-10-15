import SwiftUI

/// Quick global speed limit editor shown from the status bar.
struct SpeedLimitPopover: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        Form {
            Section {
                SpeedLimitField(title: "Download:", limit: $model.globalDownloadLimit)
                SpeedLimitField(title: "Upload:", limit: $model.globalUploadLimit)
            } header: {
                Text(model.status.altSpeedEnabled ? "Alternative Speed Limits" : "Speed Limits")
            }
            Toggle("Use alternative speed limits", isOn: $model.alternativeSpeedLimits)
            Button("Global Speed Limits…") { model.sheet = .speedLimits }
        }
        .formStyle(.grouped)
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
    }
}
