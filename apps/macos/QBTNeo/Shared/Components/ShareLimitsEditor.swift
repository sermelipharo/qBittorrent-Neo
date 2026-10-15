import SwiftUI

/// qBittorrent's `TorrentShareLimitsWidget`: ratio, seeding time and inactive
/// seeding time each Default / Unlimited / Set to, plus the limit action.
/// Used by Torrent Options, the category dialog and torrent-parameter editors.
struct ShareLimitsEditor: View {
    @Binding var limits: ShareLimits
    /// "From category" instead of "Default" when the defaults come from a category.
    var fromCategory = false

    @State private var ratioMode = ShareLimitMode.default
    @State private var seedingMode = ShareLimitMode.default
    @State private var inactiveMode = ShareLimitMode.default
    @State private var ratio = 1.0
    @State private var seeding = 1_440
    @State private var inactive = 1_440

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Design.Spacing.regular, verticalSpacing: Design.Spacing.small) {
            GridRow {
                Text("Ratio:").gridColumnAlignment(.trailing).fixedSize()
                modePicker("Ratio", $ratioMode)
                TextField("Ratio", value: $ratio, format: .number.precision(.fractionLength(2)))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 90)
                    .disabled(ratioMode != .set)
            }
            GridRow {
                Text("Seeding time:").fixedSize()
                modePicker("Seeding time", $seedingMode)
                minutesField("Seeding time", $seeding, enabled: seedingMode == .set)
            }
            GridRow {
                Text("Inactive seeding time:").fixedSize()
                modePicker("Inactive seeding time", $inactiveMode)
                minutesField("Inactive seeding time", $inactive, enabled: inactiveMode == .set)
            }
            GridRow {
                Text("Action when the limit is reached:").fixedSize()
                Picker("Action", selection: $limits.action) {
                    ForEach(ShareLimits.actions, id: \.self) { action in
                        Text(ShareLimits.title(of: action, fromCategory: fromCategory)).tag(action)
                    }
                }
                .labelsHidden()
                .gridCellColumns(2)
            }
        }
        .onAppear(perform: load)
        .onChange(of: ratioMode) { store() }
        .onChange(of: seedingMode) { store() }
        .onChange(of: inactiveMode) { store() }
        .onChange(of: ratio) { store() }
        .onChange(of: seeding) { store() }
        .onChange(of: inactive) { store() }
    }

    private func modePicker(_ label: LocalizedStringKey, _ selection: Binding<ShareLimitMode>) -> some View {
        Picker(label, selection: selection) {
            ForEach(ShareLimitMode.allCases) { mode in
                Text(mode.title(fromCategory: fromCategory)).tag(mode)
            }
        }
        .labelsHidden()
        .fixedSize()
    }

    private func minutesField(_ label: LocalizedStringKey, _ value: Binding<Int>, enabled: Bool) -> some View {
        HStack(spacing: Design.Spacing.tight) {
            TextField(label, value: value, format: .number)
                .labelsHidden()
                .textFieldStyle(.roundedBorder)
                .frame(width: 90)
            Text("min").foregroundStyle(.secondary)
        }
        .disabled(!enabled)
    }

    private func load() {
        ratioMode = ShareLimitMode(sentinel: limits.ratio)
        seedingMode = ShareLimitMode(sentinel: Double(limits.seedingMinutes))
        inactiveMode = ShareLimitMode(sentinel: Double(limits.inactiveMinutes))
        if limits.ratio >= 0 { ratio = limits.ratio }
        if limits.seedingMinutes >= 0 { seeding = Int(limits.seedingMinutes) }
        if limits.inactiveMinutes >= 0 { inactive = Int(limits.inactiveMinutes) }
    }

    private func store() {
        var next = limits
        next.ratio = switch ratioMode {
        case .default: -2
        case .unlimited: -1
        case .set: max(ratio, 0)
        }
        next.seedingMinutes = Self.minutes(seedingMode, seeding)
        next.inactiveMinutes = Self.minutes(inactiveMode, inactive)
        if next != limits { limits = next }
    }

    private static func minutes(_ mode: ShareLimitMode, _ value: Int) -> Int64 {
        switch mode {
        case .default: -2
        case .unlimited: -1
        case .set: Int64(max(value, 0))
        }
    }
}
