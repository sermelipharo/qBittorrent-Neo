import Foundation
import Observation

/// Owns one `TorrentItem` per torrent and applies `MainDataUpdate` diffs in
/// place. Only structural changes (add/remove) touch the observed `items`
/// array; field changes are observed per item.
@Observable @MainActor
final class TransferStore {
    /// All torrents in arrival order.
    private(set) var items: [TorrentItem] = []
    @ObservationIgnored private var itemsByID: [String: TorrentItem] = [:]

    struct ApplyResult {
        var structureChanged = false
        var changedIDs: [String] = []

        var isEmpty: Bool { !structureChanged && changedIDs.isEmpty }
    }

    var count: Int { items.count }

    func item(_ id: String) -> TorrentItem? { itemsByID[id] }

    func items(for ids: some Sequence<String>) -> [TorrentItem] {
        ids.compactMap { itemsByID[$0] }
    }

    func apply(torrents: [TorrentInfo], removed: [String], fullUpdate: Bool) -> ApplyResult {
        var result = ApplyResult()
        var added: [TorrentItem] = []
        var removedIDs = Set(removed)

        if fullUpdate {
            let incoming = Set(torrents.map(\.hash))
            removedIDs.formUnion(itemsByID.keys.filter { !incoming.contains($0) })
        }

        for info in torrents {
            if let existing = itemsByID[info.hash] {
                if existing.update(from: info) { result.changedIDs.append(info.hash) }
            } else {
                let item = TorrentItem(info: info)
                itemsByID[info.hash] = item
                added.append(item)
                result.changedIDs.append(info.hash)
            }
        }

        removedIDs = removedIDs.filter { itemsByID[$0] != nil }
        if !removedIDs.isEmpty || !added.isEmpty {
            var next = items
            if !removedIDs.isEmpty {
                for id in removedIDs { itemsByID[id] = nil }
                next.removeAll { removedIDs.contains($0.id) }
            }
            next.append(contentsOf: added)
            items = next
            result.structureChanged = true
        }
        return result
    }

    func removeAll() {
        itemsByID.removeAll()
        items.removeAll()
    }
}
