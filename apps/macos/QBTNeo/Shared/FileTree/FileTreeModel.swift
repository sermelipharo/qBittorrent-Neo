import Foundation
import Observation

/// A torrent's content tree flattened into table rows. Owns expansion,
/// filtering (name-only, folders kept when a descendant matches), sorting
/// among siblings and priority changes. Values update in place on refresh;
/// the tree is rebuilt only when file paths change.
@Observable @MainActor
final class FileTreeModel {
    /// Visible rows in display order.
    private(set) var rows: [FileNode] = []
    var selection: Set<String> = []
    var filterText = "" {
        didSet { if filterText != oldValue { filterChanged() } }
    }
    var patternFormat: FilterPatternFormat {
        didSet { if patternFormat != oldValue { filterChanged() } }
    }
    var sortOrder: [FileSort] = [FileSort(.name)] {
        didSet { relayout() }
    }

    @ObservationIgnored private(set) var roots: [FileNode] = []
    @ObservationIgnored private var filesByIndex: [Int: FileNode] = [:]
    @ObservationIgnored private var paths: [String] = []
    @ObservationIgnored private var matcher: TextMatcher?

    init(patternFormat: FilterPatternFormat = .wildcards) {
        self.patternFormat = patternFormat
    }

    var isEmpty: Bool { roots.isEmpty }
    var fileCount: Int { filesByIndex.count }

    // MARK: Loading

    /// Builds the tree, or updates values in place when the paths are unchanged.
    func load(_ entries: [FileEntry]) {
        let newPaths = entries.map(\.path)
        if newPaths == paths {
            updateValues(entries)
        } else {
            rebuild(entries)
        }
    }

    func clear() {
        roots = []
        filesByIndex = [:]
        paths = []
        selection = []
        rows = []
    }

    private func rebuild(_ entries: [FileEntry]) {
        let expanded = Set(rows.filter { $0.isExpanded }.map(\.path))
        paths = entries.map(\.path)
        filesByIndex = [:]
        var folders: [String: FileNode] = [:]
        var topLevel: [FileNode] = []

        for entry in entries {
            let components = entry.path.split(separator: "/").map(String.init)
            var parent: FileNode?
            var prefix = ""
            for (depth, component) in components.dropLast().enumerated() {
                prefix = prefix.isEmpty ? component : prefix + "/" + component
                if let folder = folders[prefix] {
                    parent = folder
                    continue
                }
                let folder = FileNode(id: "d" + prefix, name: component, path: prefix, isFolder: true, fileIndex: -1, depth: depth)
                folder.isExpanded = expanded.contains(prefix)
                folder.parent = parent
                if let parent { parent.children.append(folder) } else { topLevel.append(folder) }
                folders[prefix] = folder
                parent = folder
            }
            let file = FileNode(
                id: "f\(entry.index)", name: components.last ?? entry.path, path: entry.path, isFolder: false,
                fileIndex: entry.index, depth: components.count - 1, size: entry.size, progress: entry.progress,
                priority: FilePriorityChoice(entry.priority), availability: entry.availability
            )
            file.parent = parent
            if let parent { parent.children.append(file) } else { topLevel.append(file) }
            filesByIndex[entry.index] = file
        }
        roots = topLevel
        for root in roots { root.aggregate() }
        if expanded.isEmpty { autoExpand() }
        selection = selection.filter { id in rows.contains { $0.id == id } }
        relayout()
    }

    private func updateValues(_ entries: [FileEntry]) {
        for entry in entries {
            guard let node = filesByIndex[entry.index] else { continue }
            node.size = entry.size
            node.progress = entry.progress
            node.priority = FilePriorityChoice(entry.priority)
            node.availability = entry.availability
            node.remaining = node.priority == .ignored ? 0 : Int64(Double(entry.size) * (1 - entry.progress))
        }
        for root in roots { root.aggregate() }
        if sortOrder.first?.column != .name { relayout() }
    }

    /// Expands down while each level has exactly one child (single root folder).
    private func autoExpand() {
        var level = roots
        while level.count == 1, let only = level.first, only.isFolder {
            only.isExpanded = true
            level = only.children
        }
    }

    // MARK: Layout

    func relayout() {
        var next: [FileNode] = []
        next.reserveCapacity(rows.count)
        append(roots, into: &next)
        if next.count != rows.count || zip(next, rows).contains(where: { $0 !== $1 }) {
            rows = next
        }
    }

    private func append(_ nodes: [FileNode], into result: inout [FileNode]) {
        let order = sortOrder.first ?? FileSort(.name)
        let sorted = nodes.sorted { FileSort.compare(order.column, order: order.order, $0, $1) == .orderedAscending }
        for node in sorted where isVisible(node) {
            result.append(node)
            if node.isFolder, node.isExpanded || matcher != nil {
                append(node.children, into: &result)
            }
        }
    }

    private func isVisible(_ node: FileNode) -> Bool {
        guard let matcher else { return true }
        if matcher.matches(node.name) { return true }
        return node.isFolder && node.children.contains(where: isVisible)
    }

    private func filterChanged() {
        matcher = patternFormat.matcher(for: filterText)
        if matcher == nil {
            // Clearing the filter collapses everything, then expands the first root.
            for node in allNodes() where node.isFolder { node.isExpanded = false }
            autoExpand()
            roots.first?.isExpanded = true
        }
        relayout()
    }

    // MARK: Expansion

    func toggleExpanded(_ node: FileNode) {
        guard node.isFolder else { return }
        node.isExpanded.toggle()
        relayout()
    }

    func setExpanded(_ expanded: Bool, for nodes: [FileNode]) {
        for node in nodes where node.isFolder { node.isExpanded = expanded }
        relayout()
    }

    func expandAll() {
        for node in allNodes() where node.isFolder { node.isExpanded = true }
        relayout()
    }

    // MARK: Priorities

    var selectedNodes: [FileNode] { rows.filter { selection.contains($0.id) } }

    /// Sets the priority of `nodes` (folders push it to every descendant) and
    /// returns the affected file indexes grouped by priority.
    @discardableResult
    func setPriority(_ choice: FilePriorityChoice, for nodes: [FileNode]) -> [FilePriority: [Int64]] {
        guard let priority = choice.filePriority else { return [:] }
        var changed: [FilePriority: [Int64]] = [:]
        for node in nodes {
            for file in files(under: node) where file.priority != choice {
                file.priority = choice
                file.remaining = choice == .ignored ? 0 : Int64(Double(file.size) * (1 - file.progress))
                changed[priority, default: []].append(Int64(file.fileIndex))
            }
        }
        for root in roots { root.aggregate() }
        return changed
    }

    /// Space / checkbox toggle: if the first node is checked everything becomes
    /// unchecked (Do not download), otherwise checked (Normal).
    @discardableResult
    func toggleChecked(_ nodes: [FileNode]) -> [FilePriority: [Int64]] {
        guard let first = nodes.first else { return [:] }
        return setPriority(first.checkState == .checked ? .ignored : .normal, for: nodes)
    }

    @discardableResult
    func setAllChecked(_ checked: Bool) -> [FilePriority: [Int64]] {
        setPriority(checked ? .normal : .ignored, for: roots)
    }

    /// "By shown file order": selected rows in display order split into three
    /// groups (size max(n/3, 1)): Maximum, High, then Normal.
    @discardableResult
    func prioritizeByShownOrder(_ nodes: [FileNode]) -> [FilePriority: [Int64]] {
        let ordered = rows.filter { row in nodes.contains { $0 === row } }
        let group = max(ordered.count / 3, 1)
        var changed: [FilePriority: [Int64]] = [:]
        for (offset, node) in ordered.enumerated() {
            let choice: FilePriorityChoice = offset < group ? .maximum : (offset < group * 2 ? .high : .normal)
            for (priority, indexes) in setPriority(choice, for: [node]) {
                changed[priority, default: []].append(contentsOf: indexes)
            }
        }
        return changed
    }

    /// Per-file priorities in file index order (Add Torrent dialog).
    var filePriorities: [FilePriority] {
        filesByIndex.keys.sorted().compactMap { filesByIndex[$0]?.priority.filePriority }
    }

    /// Total size of wanted files.
    var wantedSize: Int64 {
        filesByIndex.values.filter { $0.priority != .ignored }.reduce(0) { $0 + $1.size }
    }

    func files(under node: FileNode) -> [FileNode] {
        node.isFolder ? node.children.flatMap { files(under: $0) } : [node]
    }

    func node(forFileIndex index: Int) -> FileNode? { filesByIndex[index] }

    private func allNodes() -> [FileNode] {
        var result: [FileNode] = []
        func walk(_ nodes: [FileNode]) {
            for node in nodes {
                result.append(node)
                walk(node.children)
            }
        }
        walk(roots)
        return result
    }
}
