import SwiftUI

/// Compact progress bar with centered percentage text that inverts over the
/// filled part (qBittorrent's table progress delegate).
struct ProgressBarView: View {
    let progress: Double
    var tint: Color = .accentColor
    var isDimmed = false
    var height = Design.Size.tableProgressBarHeight

    var body: some View {
        let text = ValueFormatter.progress(progress)
        let label = Text(text).font(.caption.monospacedDigit())
        let fill = isDimmed ? AnyShapeStyle(.tertiary) : AnyShapeStyle(tint)
        ZStack {
            RoundedRectangle(cornerRadius: Design.Radius.small)
                .fill(.quaternary)
            label
                .foregroundStyle(.secondary)
            ZStack {
                RoundedRectangle(cornerRadius: Design.Radius.small)
                    .fill(fill)
                label
                    .foregroundStyle(.white)
            }
            .mask(alignment: .leading) {
                Rectangle().scaleEffect(x: min(max(progress, 0), 1), anchor: .leading)
            }
        }
        .lineLimit(1)
        .frame(height: height)
        .accessibilityElement()
        .accessibilityLabel(Text("Progress"))
        .accessibilityValue(Text(text))
    }
}
