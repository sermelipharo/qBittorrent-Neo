import SwiftUI

/// "Select Graphs" menu with one checkable entry per series.
struct SpeedSeriesMenu: View {
    @Binding var selection: Set<SpeedGraphSeries>

    var body: some View {
        Menu("Select Graphs", systemImage: "chart.line.uptrend.xyaxis") {
            ForEach(SpeedGraphSeries.allCases) { series in
                Toggle(series.title, isOn: $selection[contains: series])
            }
        }
        .fixedSize()
    }
}

extension Set {
    /// Membership as a bindable Boolean (`$set[contains: element]`).
    subscript(contains element: Element) -> Bool {
        get { contains(element) }
        set {
            if newValue { insert(element) } else { remove(element) }
        }
    }
}
