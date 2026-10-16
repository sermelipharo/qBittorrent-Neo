import SwiftUI

/// The icon and color of a category or tag, chosen in its editor. GUI-only:
/// qBittorrent's `categories.json` and the WebAPI carry neither, so the app
/// keeps them in its own settings (`LabelAppearanceStore`). Nil fields use the
/// defaults (folder / tag symbol, accent / orange).
struct LabelAppearance: Hashable, Sendable {
    enum Kind: Sendable {
        case category
        case tag

        var defaultSymbol: String {
            switch self {
            case .category: Symbol.folderFill
            case .tag: Symbol.tagFill
            }
        }

        var defaultColor: Color {
            switch self {
            case .category: .accentColor
            case .tag: .orange
            }
        }
    }

    var symbol: String?
    var color: LabelColor?

    var isDefault: Bool { symbol == nil && color == nil }

    func resolvedSymbol(_ kind: Kind) -> String { symbol ?? kind.defaultSymbol }

    func resolvedColor(_ kind: Kind) -> Color { color?.color ?? kind.defaultColor }

    // MARK: Storage (property-list dictionary)

    init(symbol: String? = nil, color: LabelColor? = nil) {
        self.symbol = symbol
        self.color = color
    }

    init(storage: [String: String]) {
        symbol = storage["symbol"].flatMap { $0.isEmpty ? nil : $0 }
        color = storage["color"].flatMap(LabelColor.init(storage:))
    }

    var storage: [String: String] {
        var result: [String: String] = [:]
        if let symbol { result["symbol"] = symbol }
        if let color { result["color"] = color.storage }
        return result
    }
}
