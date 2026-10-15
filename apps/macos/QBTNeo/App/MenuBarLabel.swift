import SwiftUI

/// The menu bar item: a template SF Symbol (no circle) plus optional live
/// text. It reads rates and counts only for the parts that are shown, so an
/// icon-only item is never invalidated by transfer updates.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        let text = title(mode: model.gui.menuBarContentMode)
        MenuBarLabelContent(
            symbol: model.status.altSpeedEnabled ? Symbol.tortoise : Symbol.arrowUpArrowDown,
            text: text, showsIcon: model.gui.menuBarShowsIcon
        )
    }

    private func title(mode: MenuBarContentMode) -> String {
        let gui = model.gui
        var parts: [String] = []
        if mode.showsSpeed,
           let speed = MenuBarTitle.speed(
               download: model.status.downloadRate, upload: model.status.uploadRate,
               direction: gui.menuBarSpeedDirection, hidesZero: gui.menuBarHidesZeroSpeed
           ) {
            parts.append(speed)
        }
        if mode.showsCount {
            parts.append(MenuBarTitle.count(
                active: model.status.activeTorrents, total: model.status.totalTorrents, style: gui.menuBarCountStyle
            ))
        }
        return parts.joined(separator: "  ")
    }
}

/// The drawn item; the icon is forced on when there is no text.
struct MenuBarLabelContent: View {
    let symbol: String
    let text: String
    let showsIcon: Bool

    var body: some View {
        HStack(spacing: 4) {
            if showsIcon || text.isEmpty {
                Image(systemName: symbol)
            }
            if !text.isEmpty {
                Text(text).monospacedDigit()
            }
        }
        .accessibilityLabel("qBittorrent Neo")
    }
}
