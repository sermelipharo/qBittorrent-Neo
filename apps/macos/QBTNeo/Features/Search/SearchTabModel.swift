import Foundation
import Observation

/// One search job tab (features.md §5.8.1): results polled from the core,
/// the result filters, sorting, selection and visited rows.
@Observable @MainActor
final class SearchTabModel: Identifiable {
    enum Status: Equatable {
        /// A restored tab: its results are shown, no search is running.
        case ready, ongoing, finished, noResults, aborted, error(String)

        var text: String {
            switch self {
            case .ready: ""
            case .ongoing: String(localized: "Searching...")
            case .finished: String(localized: "Search has finished")
            case .noResults: String(localized: "Search returned no results")
            case .aborted: String(localized: "Search aborted")
            case .error: String(localized: "An error occurred during search...")
            }
        }

        var symbol: String {
            switch self {
            case .ready: "magnifyingglass"
            case .ongoing: "clock"
            case .finished: "checkmark.circle"
            case .noResults: "exclamationmark.triangle"
            case .aborted: "xmark.circle"
            case .error: "exclamationmark.octagon"
            }
        }
    }

    let id: UUID
    /// -1 for a restored tab that has not been searched again.
    private(set) var jobID: Int64
    private(set) var pattern: String
    private(set) var status = Status.ongoing
    private(set) var rows: [SearchResultRow] = []
    private(set) var visibleRows: [SearchResultRow] = []
    var visited: Set<SearchResultRow.ID> = []
    var selection: Set<SearchResultRow.ID> = []
    var sortOrder = [KeyPathComparator(\SearchResultRow.seeders, order: .reverse)] { didSet { applyFilters() } }

    var filterText = "" { didSet { applyFilters() } }
    var namesOnly = true { didSet { applyFilters() } }
    var minSeeds: Int64 = 0 { didSet { applyFilters() } }
    var maxSeeds: Int64 = 0 { didSet { applyFilters() } }
    var minSize = 0.0 { didSet { applyFilters() } }
    var minSizeUnit = SearchSizeUnit.mib { didSet { applyFilters() } }
    var maxSize = 0.0 { didSet { applyFilters() } }
    var maxSizeUnit = SearchSizeUnit.gib { didSet { applyFilters() } }

    @ObservationIgnored private var client: (any SearchClient)?
    @ObservationIgnored private var pollTask: Task<Void, Never>?

    /// Called when a search stops for any reason (results can be stored).
    @ObservationIgnored var didStop: (@MainActor (SearchTabModel) -> Void)?

    init(jobID: Int64, pattern: String, client: any SearchClient) {
        id = UUID()
        self.jobID = jobID
        self.pattern = pattern
        self.client = client
        startPolling()
    }

    /// A tab restored from the saved session, optionally with stored results.
    init(restoredID: UUID, pattern: String, results: [SearchResult], client: any SearchClient) {
        id = restoredID
        jobID = -1
        self.pattern = pattern
        self.client = client
        status = .ready
        rows = results.enumerated().map { SearchResultRow(id: $0.offset, result: $0.element) }
        applyFilters()
    }

    /// "Refresh tab": re-runs the search in this tab.
    func restart(jobID: Int64) {
        if let client, self.jobID >= 0 { try? client.searchDelete(id: self.jobID) }
        self.jobID = jobID
        rows = []
        visited = []
        selection = []
        status = .ongoing
        applyFilters()
        startPolling()
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, let client = self.client else { return }
                let jobID = self.jobID
                let offset = Int64(self.rows.count)
                let page = await CoreCall.run { try? client.searchResults(id: jobID, limit: 0, offset: offset) }
                let info = await CoreCall.run { (try? client.searchStatus(id: jobID))?.first }
                guard let page else { return }
                self.append(page.results)
                if page.status == .stopped {
                    self.finish(info)
                    return
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func append(_ results: [SearchResult]) {
        guard !results.isEmpty else { return }
        let start = rows.count
        rows += results.enumerated().map { SearchResultRow(id: start + $0.offset, result: $0.element) }
        applyFilters()
    }

    private func finish(_ info: SearchJobInfo?) {
        switch info?.outcome {
        case .aborted: status = .aborted
        case .error: status = .error(info?.error ?? "")
        case .noResults: status = .noResults
        default: status = rows.isEmpty ? .noResults : .finished
        }
        didStop?(self)
    }

    func stop() {
        guard jobID >= 0 else { return }
        try? client?.searchStop(id: jobID)
        pollTask?.cancel()
        status = .aborted
        didStop?(self)
    }

    func close() {
        pollTask?.cancel()
        if jobID >= 0 { try? client?.searchDelete(id: jobID) }
    }

    // MARK: Filtering

    func refilter() {
        applyFilters()
    }

    private func applyFilters() {
        let matcher = SearchFilter(
            text: filterText, regex: UserDefaults.standard.bool(forKey: FeatureDefaults.searchUsesRegex),
            pattern: pattern, namesOnly: namesOnly
        )
        let minBytes = minSizeUnit.bytes(minSize)
        let maxBytes = maxSizeUnit.bytes(maxSize)
        visibleRows = rows.filter { row in
            if minSeeds > 0, row.seeders < minSeeds { return false }
            if maxSeeds > 0, row.seeders > maxSeeds { return false }
            if minBytes > 0, Double(row.size) < minBytes { return false }
            if maxBytes > 0, Double(row.size) > maxBytes { return false }
            return matcher.matches(row.name)
        }
        .sorted(using: sortOrder)
    }

    /// The raw results, for storing.
    var results: [SearchResult] { rows.map(\.result) }

    var selectedRows: [SearchResultRow] { rows.filter { selection.contains($0.id) } }
}
