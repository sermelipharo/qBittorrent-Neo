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
                SpeedChart(points: model.properties.speedPoints, series: gui.speedGraphSeries)
            }
            .padding(Design.Spacing.medium)
        } else {
            ContentUnavailableView("Speed graphs are disabled", systemImage: "chart.xyaxis.line",
                                   description: Text("You can enable it in Advanced Options"))
        }
    }
}
