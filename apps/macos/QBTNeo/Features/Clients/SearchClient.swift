import Foundation

/// Search engine calls of the core facade (`api_search.rs`, nova3 plugins).
///
protocol SearchClient: AnyObject, Sendable {
    func searchEngineStatus() -> SearchEngineStatus
    func searchPlugins() -> [SearchPlugin]
    func searchInstallPlugins(sources: [String]) async throws
    func searchUninstallPlugins(names: [String]) throws
    func searchEnablePlugins(names: [String], enable: Bool) throws
    func searchUpdatePlugins() async throws
    func searchStart(pattern: String, plugins: [String], category: String) throws -> Int64
    func searchStop(id: Int64) throws
    func searchStatus(id: Int64?) throws -> [SearchJobInfo]
    func searchResults(id: Int64, limit: Int64, offset: Int64) throws -> SearchResultsPage
    func searchDelete(id: Int64) throws
    func searchDownloadTorrent(url: String, plugin: String, params: AddTorrentParams) async throws
}
