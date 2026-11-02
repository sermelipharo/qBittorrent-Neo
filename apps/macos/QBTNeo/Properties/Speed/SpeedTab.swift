import Charts
import SwiftUI

/// Speed tab (features.md §2.8): global speed history with period and
/// series pickers.
struct SpeedTab: View {
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        @Bindable var gui = gui
        if gui.speedGraphsEnabled {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                HStack {
                    Picker("Period:", selection: $gui.speedGraphPeriod) {
                        ForEach(SpeedGraphPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .fixedSize()
                    Spacer()
                    SpeedSeriesMenu(selection: $gui.speedGraphSeries)
                }
                .controlSize(.small)
                SpeedChart(properties: model.properties, series: gui.speedGraphSeries)
            }
            .padding(Design.Spacing.medium)
        } else {
            // The hint opens the setting, as qBittorrent 5.3's link does.
            ContentUnavailableView {
                Label("Speed graphs are disabled", systemImage: Symbol.chartXyaxisLine)
            } actions: {
                Button("You can enable it in Advanced Options") { model.revealSetting("SpeedWidget/Enabled") }
                    .buttonStyle(.link)
            }
        }
    }
}
