import SwiftUI

/// Right-click menu of the status-bar speed buttons: quick limit presets.
struct SpeedPresetMenu: View {
    let direction: SpeedStatusButton.Direction
    @Environment(AppModel.self) private var model

    private static let presetsKiB: [Int64] = [100, 500, 1_024, 5_120, 10_240]

    var body: some View {
        Button("Set Global Speed Limits…", systemImage: "speedometer") { model.sheet = .speedLimits }
        Toggle("Alternative Speed Limits", isOn: Bindable(model).alternativeSpeedLimits)
        Divider()
        Button("Unlimited") { set(0) }
        ForEach(Self.presetsKiB, id: \.self) { kib in
            Button(UnitFormatter.speed(kib * 1_024)) { set(kib * 1_024) }
        }
    }

    private func set(_ limit: Int64) {
        model.perform { client in
            if direction == .download {
                try client.setGlobalDownloadLimit(limit: limit)
            } else {
                try client.setGlobalUploadLimit(limit: limit)
            }
        }
    }
}
