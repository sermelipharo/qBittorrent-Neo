import SwiftUI

/// Download or upload speed with limit and session total; click for the
/// speed-limit popover, right-click for presets.
struct SpeedStatusButton: View {
    enum Direction {
        case download, upload
    }

    let direction: Direction
    @Environment(AppModel.self) private var model
    @State private var showsPopover = false

    var body: some View {
        let status = model.status
        let isDownload = direction == .download
        let rate = isDownload ? status.downloadRate : status.uploadRate
        let limit = isDownload ? status.downloadLimit : status.uploadLimit
        let total = isDownload ? status.downloadSession : status.uploadSession
        Button {
            showsPopover = true
        } label: {
            Label {
                Text(text(rate: rate, limit: limit, total: total))
                    .monospacedDigit()
            } icon: {
                Image(systemName: isDownload ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .foregroundStyle(isDownload ? Design.Palette.download : Design.Palette.upload)
            }
            .fixedSize()
        }
        .buttonStyle(.borderless)
        .help(isDownload ? "Global download speed limit" : "Global upload speed limit")
        .popover(isPresented: $showsPopover, arrowEdge: .top) {
            SpeedLimitPopover()
        }
        .contextMenu {
            SpeedPresetMenu(direction: direction)
        }
    }

    private func text(rate: Int64, limit: Int64, total: Int64) -> String {
        var text = UnitFormatter.speed(rate)
        if limit > 0 { text += " [\(UnitFormatter.speed(limit))]" }
        text += " (\(UnitFormatter.size(total)))"
        return text
    }
}
