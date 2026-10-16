import SwiftUI

/// One transfer-list cell. Each cell reads only the item properties its
/// column needs, so a speed change redraws just the speed cells.
struct TransferCell: View {
    let item: TorrentItem
    let column: TransferColumn
    // Passed in rather than read from the environment: table cells can be
    // built outside the window's environment (accessibility hit tests).
    let gui: GUIPreferences
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        switch column {
        case .name:
            Label {
                Text(item.name)
                    .foregroundStyle(textStyle(.name))
            } icon: {
                Image(systemName: item.state.systemImage)
                    .foregroundStyle(prominence == .increased ? AnyShapeStyle(.primary) : AnyShapeStyle(item.state.color))
                    .accessibilityLabel(Text(item.state.statusText))
            }
            .lineLimit(1)
            .help(item.name)
        case .progress:
            ProgressBarView(
                progress: item.progress,
                tint: gui.stateColorScope.colorsProgressBar ? item.state.color : .accentColor,
                isDimmed: item.state.dimsProgressBar
            )
        default:
            let hideZero = gui.hidesZeroValues(isStoppedDownloading: item.state == .stoppedDownloading)
            let text = TransferCellText.text(column, item, hideZero: hideZero)
            Text(text)
                .foregroundStyle(textStyle(column))
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(column == .savePath || column == .incompletePath ? .middle : .tail)
                .help(TransferCellText.hasTooltip(column) ? text : "")
        }
    }

    private func textStyle(_ column: TransferColumn) -> AnyShapeStyle {
        guard gui.stateColorScope.colorsText(of: column), prominence != .increased else { return AnyShapeStyle(.primary) }
        return AnyShapeStyle(item.state.color)
    }
}
