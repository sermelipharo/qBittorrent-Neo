import Foundation
import Observation

/// Manage Cookies window state (features.md §3.17). Edits stay local until
/// Save, which replaces the whole cookie jar; Revert reloads it.
@Observable @MainActor
final class CookiesModel {
    var rows: [CookieRow] = []
    var selection: Set<CookieRow.ID> = []
    var sortOrder = [KeyPathComparator(\CookieRow.domain)]
    private(set) var savedRows: [CookieRow] = []
    var errorMessage: String?

    @ObservationIgnored private var client: (any AppInfoClient)?

    var hasChanges: Bool { rows.map(\.cookie) != savedRows.map(\.cookie) }

    func load(client: (any CoreClient)?) async {
        guard let client = client as? any AppInfoClient else { return }
        self.client = client
        let cookies = await CoreCall.run { client.cookies() }
        rows = cookies.map(CookieRow.init).sorted(using: sortOrder)
        savedRows = rows
        selection = []
    }

    subscript(row id: CookieRow.ID) -> CookieRow {
        get { rows.first { $0.id == id } ?? CookieRow(id: id, expiration: .now) }
        set {
            guard let index = rows.firstIndex(where: { $0.id == id }) else { return }
            rows[index] = newValue
        }
    }

    /// Inserts an empty cookie after the selected row, expiring in two years.
    func add() {
        let row = CookieRow(expiration: Calendar.current.date(byAdding: .year, value: 2, to: .now) ?? .now)
        let anchor = rows.lastIndex { selection.contains($0.id) }
        rows.insert(row, at: anchor.map { $0 + 1 } ?? rows.endIndex)
        selection = [row.id]
    }

    func removeSelected() {
        rows.removeAll { selection.contains($0.id) }
        selection = []
    }

    func sort() {
        rows.sort(using: sortOrder)
    }

    func save() {
        guard let client else { return }
        let cookies = rows.map(\.cookie).filter { !$0.name.isEmpty && !$0.domain.isEmpty }
        do {
            try client.setCookies(cookies: cookies)
            savedRows = rows
            errorMessage = nil
        } catch {
            errorMessage = error.userMessage
        }
    }

    func revert() {
        rows = savedRows
        selection = []
    }
}
