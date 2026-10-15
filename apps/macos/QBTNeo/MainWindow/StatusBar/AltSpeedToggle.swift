import SwiftUI

/// Alternative speed limits toggle (turtle).
struct AltSpeedToggle: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let enabled = model.status.altSpeedEnabled
        Toggle(isOn: Bindable(model).alternativeSpeedLimits) {
            Label("Alternative Speed Limits", systemImage: "tortoise.fill")
                .labelStyle(.iconOnly)
        }
        .toggleStyle(.button)
        .buttonStyle(.borderless)
        .foregroundStyle(enabled ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
        .help(enabled ? "Click to switch to regular speed limits" : "Click to switch to alternative speed limits")
    }
}
