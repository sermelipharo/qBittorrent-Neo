import Foundation
import Observation

/// Search state of the symbol picker. The full symbol list is read on the
/// first search and released with the picker.
@Observable @MainActor
final class SymbolPickerModel {
    var query = "" {
        didSet { update() }
    }
    private(set) var results = SymbolCatalog.curated
    @ObservationIgnored private var allNames: [String]?

    private func update() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = SymbolCatalog.curated
            return
        }
        if allNames == nil { allNames = SymbolCatalog.loadAll() }
        results = SymbolCatalog.search(trimmed, in: allNames ?? SymbolCatalog.curated)
    }
}
