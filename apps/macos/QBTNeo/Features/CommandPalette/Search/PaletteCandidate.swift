import Foundation

/// A searchable row: the item with its title and keywords folded once.
struct PaletteCandidate {
    let item: PaletteItem
    let title: FoldedText
    let keywords: [FoldedText]

    init(_ item: PaletteItem, keywords: [String] = []) {
        self.item = item
        title = FoldedText(item.title)
        self.keywords = keywords.map(FoldedText.init)
    }
}
