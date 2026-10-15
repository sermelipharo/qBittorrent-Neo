import Foundation

/// Torrent actions, trackers, peers, web seeds, categories and tags.
extension QtCoreClient {
    // MARK: Torrent actions

    func startTorrents(hashes: [String]) async throws {
        try await bridge.callAsyncVoid("startTorrents", ["hashes": hashes])
    }

    func stopTorrents(hashes: [String]) async throws {
        try await bridge.callAsyncVoid("stopTorrents", ["hashes": hashes])
    }

    func setForceStart(hashes: [String], value: Bool) async throws {
        try await bridge.callAsyncVoid("setForceStart", ["hashes": hashes, "value": value])
    }

    func removeTorrents(hashes: [String], deleteFiles: Bool) async throws {
        try await bridge.callAsyncVoid("removeTorrents", ["hashes": hashes, "deleteFiles": deleteFiles])
    }

    func recheckTorrents(hashes: [String]) async throws {
        try await bridge.callAsyncVoid("recheckTorrents", ["hashes": hashes])
    }

    func reannounceTorrents(hashes: [String]) async throws {
        try await bridge.callAsyncVoid("reannounceTorrents", ["hashes": hashes])
    }

    func setLocation(hashes: [String], location: String) async throws {
        try await bridge.callAsyncVoid("setLocation", ["hashes": hashes, "location": location])
    }

    func setSavePath(hashes: [String], path: String) async throws {
        try await bridge.callAsyncVoid("setSavePath", ["hashes": hashes, "path": path])
    }

    func setDownloadPath(hashes: [String], path: String) async throws {
        try await bridge.callAsyncVoid("setDownloadPath", ["hashes": hashes, "path": path])
    }

    func renameTorrent(hash: String, name: String) throws {
        try bridge.callVoid("renameTorrent", ["hash": hash, "name": name])
    }

    func renameFile(hash: String, oldPath: String, newPath: String) async throws {
        try await bridge.callAsyncVoid("renameFile", ["hash": hash, "oldPath": oldPath, "newPath": newPath])
    }

    func renameFolder(hash: String, oldPath: String, newPath: String) async throws {
        try await bridge.callAsyncVoid("renameFolder", ["hash": hash, "oldPath": oldPath, "newPath": newPath])
    }

    func setFilePriority(hash: String, indexes: [Int64], priority: FilePriority) throws {
        try bridge.callVoid("setFilePriority", ["hash": hash, "indexes": indexes, "priority": priority])
    }

    func setAutoManagement(hashes: [String], enabled: Bool) throws {
        try bridge.callVoid("setAutoManagement", ["hashes": hashes, "enabled": enabled])
    }

    func setDownloadLimit(hashes: [String], limit: Int64) throws {
        try bridge.callVoid("setDownloadLimit", ["hashes": hashes, "limit": limit])
    }

    func setUploadLimit(hashes: [String], limit: Int64) throws {
        try bridge.callVoid("setUploadLimit", ["hashes": hashes, "limit": limit])
    }

    func setShareLimits(
        hashes: [String],
        ratioLimit: Double,
        seedingTimeLimit: Int64,
        inactiveSeedingTimeLimit: Int64,
        action: ShareLimitAction
    ) throws {
        try bridge.callVoid("setShareLimits", [
            "hashes": hashes, "ratioLimit": ratioLimit, "seedingTimeLimit": seedingTimeLimit,
            "inactiveSeedingTimeLimit": inactiveSeedingTimeLimit, "action": action,
        ])
    }

    func setSuperSeeding(hashes: [String], value: Bool) throws {
        try bridge.callVoid("setSuperSeeding", ["hashes": hashes, "value": value])
    }

    func setSequentialDownload(hashes: [String], value: Bool) throws {
        try bridge.callVoid("setSequentialDownload", ["hashes": hashes, "value": value])
    }

    func setFirstLastPiecePriority(hashes: [String], value: Bool) throws {
        try bridge.callVoid("setFirstLastPiecePriority", ["hashes": hashes, "value": value])
    }

    func discoveryOptions(hashes: [String]) -> [TorrentDiscoveryOptions] {
        bridge.value("discoveryOptions", ["hashes": hashes], fallback: [])
    }

    func setDhtDisabled(hashes: [String], value: Bool) throws {
        try bridge.callVoid("setDhtDisabled", ["hashes": hashes, "value": value])
    }

    func setPexDisabled(hashes: [String], value: Bool) throws {
        try bridge.callVoid("setPexDisabled", ["hashes": hashes, "value": value])
    }

    func setLsdDisabled(hashes: [String], value: Bool) throws {
        try bridge.callVoid("setLsdDisabled", ["hashes": hashes, "value": value])
    }

    func queueIncrease(hashes: [String]) throws {
        try bridge.callVoid("queueIncrease", ["hashes": hashes])
    }

    func queueDecrease(hashes: [String]) throws {
        try bridge.callVoid("queueDecrease", ["hashes": hashes])
    }

    func queueTop(hashes: [String]) throws {
        try bridge.callVoid("queueTop", ["hashes": hashes])
    }

    func queueBottom(hashes: [String]) throws {
        try bridge.callVoid("queueBottom", ["hashes": hashes])
    }

    // MARK: Trackers, peers, web seeds

    func addTrackers(hash: String, trackers: [TrackerTierEntry]) throws {
        try bridge.callVoid("addTrackers", ["hash": hash, "trackers": trackers])
    }

    func editTracker(hash: String, origUrl: String, newUrl: String) throws {
        try bridge.callVoid("editTracker", ["hash": hash, "origUrl": origUrl, "newUrl": newUrl])
    }

    func removeTrackers(hash: String, urls: [String]) throws {
        try bridge.callVoid("removeTrackers", ["hash": hash, "urls": urls])
    }

    func replaceTrackers(hash: String, trackers: [TrackerTierEntry]) throws {
        try bridge.callVoid("replaceTrackers", ["hash": hash, "trackers": trackers])
    }

    func addPeers(hashes: [String], peers: [String]) throws {
        try bridge.callVoid("addPeers", ["hashes": hashes, "peers": peers])
    }

    func banPeers(peers: [String]) throws {
        try bridge.callVoid("banPeers", ["peers": peers])
    }

    func addWebSeeds(hash: String, urls: [String]) throws {
        try bridge.callVoid("addWebSeeds", ["hash": hash, "urls": urls])
    }

    func editWebSeed(hash: String, origUrl: String, newUrl: String) throws {
        try bridge.callVoid("editWebSeed", ["hash": hash, "origUrl": origUrl, "newUrl": newUrl])
    }

    func removeWebSeeds(hash: String, urls: [String]) throws {
        try bridge.callVoid("removeWebSeeds", ["hash": hash, "urls": urls])
    }

    // MARK: Categories and tags

    func categories() -> [Category] {
        bridge.value("categories", fallback: [])
    }

    func createCategory(category: Category) throws {
        try bridge.callVoid("createCategory", ["category": category])
    }

    func editCategory(category: Category) throws {
        try bridge.callVoid("editCategory", ["category": category])
    }

    func removeCategories(names: [String]) throws {
        try bridge.callVoid("removeCategories", ["names": names])
    }

    func setCategory(hashes: [String], category: String) throws {
        try bridge.callVoid("setCategory", ["hashes": hashes, "category": category])
    }

    func tags() -> [String] {
        bridge.value("tags", fallback: [])
    }

    func createTags(tags: [String]) throws {
        try bridge.callVoid("createTags", ["tags": tags])
    }

    func deleteTags(tags: [String]) throws {
        try bridge.callVoid("deleteTags", ["tags": tags])
    }

    func addTags(hashes: [String], tags: [String]) throws {
        try bridge.callVoid("addTags", ["hashes": hashes, "tags": tags])
    }

    func removeTags(hashes: [String], tags: [String]) throws {
        try bridge.callVoid("removeTags", ["hashes": hashes, "tags": tags])
    }
}
