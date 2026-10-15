import SwiftUI

/// "Filter search results…", the result count, "Search in:", Seeds and Size ranges.
struct SearchFilterBar: View {
    @Bindable var tab: SearchTabModel
    @AppStorage(FeatureDefaults.searchUsesRegex) private var usesRegex = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Design.Spacing.large) {
                filterRow
                rangeRow
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                filterRow
                rangeRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .controlSize(.small)
        .padding(.horizontal, Design.Spacing.medium)
        .padding(.vertical, Design.Spacing.small)
        .onChange(of: usesRegex) { tab.refilter() }
    }

    private var filterRow: some View {
        HStack(spacing: Design.Spacing.small) {
            TextField("Filter", text: $tab.filterText, prompt: Text("Filter search results…"))
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 160, maxWidth: 240)
            Toggle("Regex", isOn: $usesRegex)
                .toggleStyle(.checkbox)
                .help("Use regular expressions")
            Text("Results (showing \(tab.visibleRows.count) out of \(tab.rows.count)):")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .fixedSize()
        }
    }

    private var rangeRow: some View {
        HStack(spacing: Design.Spacing.large) {
            Picker("Search in:", selection: $tab.namesOnly) {
                Text("Torrent names only").tag(true)
                Text("Everywhere").tag(false)
            }
            .fixedSize()
            .help("Torrent names only: every word of the search must appear in the name")
            HStack(spacing: Design.Spacing.tight) {
                Text("Seeds:")
                SpinControl(title: "Minimum number of seeds", value: $tab.minSeeds, range: 0...1_000, width: FeatureDesign.Width.narrowField)
                Text("to")
                SpinControl(title: "Maximum number of seeds", value: $tab.maxSeeds, range: 0...1_000, special: .infinity(),
                            width: FeatureDesign.Width.narrowField)
            }
            .help("Set minimum and maximum allowed number of seeders")
            HStack(spacing: Design.Spacing.tight) {
                Text("Size:")
                SizeBound(value: $tab.minSize, unit: $tab.minSizeUnit, title: "Minimum torrent size")
                Text("to")
                SizeBound(value: $tab.maxSize, unit: $tab.maxSizeUnit, title: "Maximum torrent size")
            }
            .help("Set minimum and maximum allowed size of a torrent")
        }
    }
}
