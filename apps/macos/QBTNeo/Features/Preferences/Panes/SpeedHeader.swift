import SwiftUI

/// Speed pane header: the last minute of speed with the limit drawn in, the
/// current speeds and the alternative-limits switch (runtime state, not a preference).
struct SpeedHeader: View {
    @Environment(AppModel.self) private var app
    @State private var sparkline = SpeedSparklineModel()

    var body: some View {
        @Bindable var app = app
        let status = app.status
        HStack(alignment: .center, spacing: Design.Spacing.large) {
            SpeedSparkline(points: sparkline.points, downloadLimit: status.downloadLimit)
                .frame(height: 44)
                .padding(Design.Spacing.small)
                .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: Design.Radius.medium))
            VStack(alignment: .leading, spacing: Design.Spacing.tight) {
                Label(UnitFormatter.speed(status.downloadRate), systemImage: Symbol.arrowDown)
                    .foregroundStyle(SpeedGraphSeries.download.color)
                Label(UnitFormatter.speed(status.uploadRate), systemImage: Symbol.arrowUp)
                    .foregroundStyle(SpeedGraphSeries.upload.color)
                Toggle(isOn: $app.alternativeSpeedLimits) {
                    Label("Alternative limits", systemImage: status.altSpeedEnabled ? Symbol.tortoiseFill : Symbol.tortoise)
                }
                .toggleStyle(.button)
                .help("Alternative Speed Limits")
            }
            .font(.callout)
            .monospacedDigit()
            .fixedSize()
        }
        .padding(.top, SettingsLayout.sectionSpacing)
        .task(id: [status.downloadRate, status.uploadRate]) {
            await sparkline.refresh(client: app.client)
        }
    }
}
