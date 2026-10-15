import Foundation

/// A section of results as shown: header and rows.
struct PaletteResultSection: Identifiable {
    let section: PaletteSection
    let items: [PaletteItem]

    var id: PaletteSection { section }
}
