import Foundation

extension DemoClient: SearchClient {
    private var store: DemoFeatureStore { .shared }

    func searchEngineStatus() -> SearchEngineStatus {
        SearchEngineStatus(pythonFound: true, pythonPath: "/usr/bin/python3", pythonVersion: "3.9.6", message: "")
    }

    func searchPlugins() -> [SearchPlugin] {
        store.search.withLock { $0.plugins }
    }

    func searchInstallPlugins(sources: [String]) async throws {
        try await Task.sleep(for: .seconds(1))
        let names = sources.map { URL(string: $0)?.deletingPathExtension().lastPathComponent ?? $0 }
        for name in names where !name.isEmpty {
            guard sources.allSatisfy({ $0.hasSuffix(".py") }) else {
                throw QbtError.InvalidArgument(message: "The link doesn't seem to point to a search engine plugin.")
            }
            store.search.withLock { state in
                state.plugins.removeAll { $0.name == name }
                state.plugins.append(SearchPlugin(
                    name: name, fullName: name.capitalized, version: "1.0", url: "https://\(name).example.org", enabled: true,
                    supportedCategories: [SearchCategory(id: "software", name: "Software")], iconPath: ""
                ))
            }
        }
    }

    func searchUninstallPlugins(names: [String]) throws {
        store.search.withLock { state in
            state.plugins.removeAll { names.contains($0.name) }
        }
    }

    func searchEnablePlugins(names: [String], enable: Bool) throws {
        store.search.withLock { state in
            for index in state.plugins.indices where names.contains(state.plugins[index].name) {
                state.plugins[index].enabled = enable
            }
        }
    }

    func searchUpdatePlugins() async throws {
        try await Task.sleep(for: .seconds(1))
    }

    func searchStart(pattern: String, plugins: [String], category: String) throws -> Int64 {
        try store.search.withLock { try $0.start(pattern: pattern, plugins: plugins, category: category) }
    }

    func searchStop(id: Int64) throws {
        try store.search.withLock { state in
            guard let job = state.jobs[id] else { throw QbtError.NotFound(message: "Search job \(id) not found") }
            try state.stop(id, elapsed: store.elapsed(since: job.start))
        }
    }

    func searchStatus(id: Int64?) throws -> [SearchJobInfo] {
        try store.search.withLock { state in
            if let id {
                guard let job = state.jobs[id] else { throw QbtError.NotFound(message: "Search job \(id) not found") }
                return [state.info(job, elapsed: store.elapsed(since: job.start))]
            }
            return state.jobs.values.sorted { $0.id < $1.id }.map { state.info($0, elapsed: store.elapsed(since: $0.start)) }
        }
    }

    func searchResults(id: Int64, limit: Int64, offset: Int64) throws -> SearchResultsPage {
        try store.search.withLock { state in
            guard let job = state.jobs[id] else { throw QbtError.NotFound(message: "Search job \(id) not found") }
            let info = state.info(job, elapsed: store.elapsed(since: job.start))
            let visible = Array(job.results.prefix(Int(info.total)))
            let start = offset < 0 ? max(visible.count + Int(offset), 0) : min(Int(offset), visible.count)
            let end = limit > 0 ? min(start + Int(limit), visible.count) : visible.count
            return SearchResultsPage(status: info.status, total: info.total, results: Array(visible[start..<end]))
        }
    }

    func searchDelete(id: Int64) throws {
        _ = store.search.withLock { $0.jobs.removeValue(forKey: id) }
    }

    func searchDownloadTorrent(url: String, plugin: String, params: AddTorrentParams) async throws {
        _ = try await addTorrent(source: .url(url: url), params: params)
    }
}
