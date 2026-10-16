import SwiftUI

/// One transfer-list cell. Each cell reads only the item properties its
/// column needs, so a speed change redraws just the speed cells.
struct TransferCell: View {
    let item: TorrentItem
    let column: TransferColumn
    // Passed in rather than read from the environment: table cells can be
    // built outside the window's environment (accessibility hit tests).
    let gui: GUIPreferences
    /// Category and tag icons/colors (passed in for the same reason as `gui`).
    let labels: LabelAppearanceStore
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
        case .category where !item.category.isEmpty:
            TransferLabelsCell(names: [item.category], kind: .category, labels: labels, textStyle: textStyle(column))
        case .tags where !item.tags.isEmpty:
            TransferLabelsCell(names: item.tags, kind: .tag, labels: labels, textStyle: textStyle(column))
        default:
            let hideZero = gui.hidesZeroValues(isStoppedDownloading: item.state == .stoppedDownloading)
            let text = TransferCellText.text(column, item, hideZero: hideZero)
            let label = Text(text)
                .foregroundStyle(textStyle(column))
                .monospacedDigit()
                .lineLimit(1)
                .truncationMode(column == .savePath || column == .incompletePath ? .middle : .tail)
            // Each modifier costs memory in every cell's hosting view: only the columns whose text is
            // long enough to be cut get a tooltip.
            if TransferCellText.hasTooltip(column) {
                label.help(text)
            } else {
                label
            }
        }
    }

    private func textStyle(_ column: TransferColumn) -> AnyShapeStyle {
        guard gui.stateColorScope.colorsText(of: column), prominence != .increased else { return AnyShapeStyle(.primary) }
        return AnyShapeStyle(item.state.color)
    }
}
