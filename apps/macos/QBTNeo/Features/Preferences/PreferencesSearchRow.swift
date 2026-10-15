import SwiftUI

/// A Settings search hit: the page with the matching setting names underneath.
struct PreferencesSearchRow: View {
    let result: PreferencesIndex.Result

    var body: some View {
        PreferencesPageLabel(page: result.page, detail: detail)
    }

    private var detail: String? {
        guard !result.matches.isEmpty else { return nil }
        let shown = result.matches.prefix(3).joined(separator: ", ")
        let extra = result.matches.count - 3
        return extra > 0 ? "\(shown), +\(extra)" : shown
    }
}
