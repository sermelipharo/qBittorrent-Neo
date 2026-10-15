import Foundation

/// Search plugins and running/finished search jobs of the demo session.
/// Results "arrive" over about two seconds after a search starts.
struct DemoSearchState: Sendable {
    struct Job: Sendable {
        let id: Int64
        let pattern: String
        let start: Date
        let results: [SearchResult]
        var stoppedAfter: Double?
    }

    static let duration = 2.4

    var plugins: [SearchPlugin] = DemoSearchCatalog.plugins
    var jobs: [Int64: Job] = [:]
    var nextID: Int64 = 1

    mutating func start(pattern: String, plugins names: [String], category: String) throws -> Int64 {
        guard !pattern.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw QbtError.InvalidArgument(message: "Please type a search pattern first")
        }
        let selected = plugins.filter { plugin in
            let wanted = names.contains("all") || (names.contains("enabled") ? plugin.enabled : names.contains(plugin.name))
            let supports = category == "all" || plugin.supportedCategories.contains { $0.id == category }
            return wanted && supports
        }
        let id = nextID
        nextID += 1
        jobs[id] = Job(id: id, pattern: pattern, start: .now, results: DemoSearchCatalog.results(pattern: pattern, plugins: selected))
        return id
    }

    mutating func stop(_ id: Int64, elapsed: Double) throws {
        guard var job = jobs[id] else { throw QbtError.NotFound(message: "Search job \(id) not found") }
        if job.stoppedAfter == nil, elapsed < Self.duration { job.stoppedAfter = elapsed }
        jobs[id] = job
    }

    /// Number of results visible after `elapsed` seconds.
    func visibleCount(_ job: Job, elapsed: Double) -> Int {
        let time = min(job.stoppedAfter ?? elapsed, Self.duration)
        return time >= Self.duration ? job.results.count : min(job.results.count, Int(time / Self.duration * Double(job.results.count)))
    }

    func info(_ job: Job, elapsed: Double) -> SearchJobInfo {
        let running = job.stoppedAfter == nil && elapsed < Self.duration
        let count = visibleCount(job, elapsed: elapsed)
        let outcome: SearchJobOutcome = if running {
            .ongoing
        } else if job.stoppedAfter != nil {
            .aborted
        } else {
            count == 0 ? .noResults : .finished
        }
        return SearchJobInfo(
            id: job.id, pattern: job.pattern, status: running ? .running : .stopped, total: Int64(count), outcome: outcome, error: ""
        )
    }
}
