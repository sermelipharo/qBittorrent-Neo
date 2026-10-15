import SwiftUI

/// Snapshot-only sheet of the menu bar item variants, each on a menu-bar-like strip.
struct MenuBarSnapshotView: View {
    private struct Variant: Identifiable {
        let caption: String
        let symbol: String
        let text: String
        var showsIcon = true
        var id: String { caption }
    }

    private var variants: [Variant] {
        let speed = MenuBarTitle.speed(download: 1_300_000, upload: 348_000, direction: .both, hidesZero: false) ?? ""
        let down = MenuBarTitle.speed(download: 12_400_000, upload: 0, direction: .download, hidesZero: false) ?? ""
        let idle = MenuBarTitle.speed(download: 0, upload: 0, direction: .both, hidesZero: false) ?? ""
        let count = MenuBarTitle.count(active: 3, total: 12, style: .activeOfTotal)
        return [
            Variant(caption: "Icon only", symbol: Symbol.arrowUpArrowDown, text: ""),
            Variant(caption: "Alternative speed limits on", symbol: Symbol.tortoise, text: ""),
            Variant(caption: "Speed", symbol: Symbol.arrowUpArrowDown, text: speed),
            Variant(caption: "Download only", symbol: Symbol.arrowUpArrowDown, text: down),
            Variant(caption: "Count", symbol: Symbol.arrowUpArrowDown, text: count),
            Variant(caption: "Speed and count", symbol: Symbol.arrowUpArrowDown, text: speed + "  " + count),
            Variant(caption: "Text only", symbol: Symbol.arrowUpArrowDown, text: speed + "  " + count, showsIcon: false),
            Variant(caption: "Idle (zeros)", symbol: Symbol.arrowUpArrowDown, text: idle),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(variants) { variant in
                HStack {
                    Text(variant.caption).font(.caption).foregroundStyle(.secondary).frame(width: 150, alignment: .leading)
                    MenuBarLabelContent(symbol: variant.symbol, text: variant.text, showsIcon: variant.showsIcon)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(.regularMaterial, in: .rect(cornerRadius: 5))
                    Spacer()
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
