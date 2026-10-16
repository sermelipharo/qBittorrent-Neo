import Foundation
import Observation

/// Navigation state of the Settings window: selected pane (restored at
/// launch), Transfers segment, the "Show advanced settings" switch, sections
/// revealed by search for this session, open disclosure groups and the
/// setting to scroll to and highlight.
@Observable @MainActor
final class SettingsNavigator {
    static let lastPaneKey = "Settings/LastPane"
    static let showAdvancedKey = "Settings/ShowAdvanced"

    var pane: SettingsPane {
        didSet { if pane != oldValue, isPersistent { defaults.set(pane.rawValue, forKey: Self.lastPaneKey) } }
    }
    var segment = TransfersSegment.adding
    /// "Show advanced settings"; hiding never changes a value.
    var showsAdvanced: Bool {
        didSet { if showsAdvanced != oldValue, isPersistent { defaults.set(showsAdvanced, forKey: Self.showAdvancedKey) } }
    }
    /// Advanced sections shown for this session after picking a search result.
    private(set) var revealedSections: Set<SettingsSection> = []
    /// Open disclosure groups, by section.
    var expandedDisclosures: Set<SettingsSection> = []
    /// The setting to scroll to; `nonce` re-triggers the same one.
    private(set) var target: SettingTarget?
    var query = ""

    /// Rows currently on screen (maintained by `SettingRow`), to find the row a search result stands for.
    @ObservationIgnored private var presentRows: Set<String> = []

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let isPersistent: Bool

    /// - Parameter persistent: false for snapshots (nothing is written to the user's defaults).
    init(defaults: UserDefaults = AppDefaults.store, persistent: Bool = true, pane: SettingsPane? = nil) {
        self.defaults = defaults
        self.isPersistent = persistent
        self.pane = pane ?? defaults.string(forKey: Self.lastPaneKey).flatMap(SettingsPane.init(rawValue:)) ?? .general
        self.showsAdvanced = defaults.bool(forKey: Self.showAdvancedKey)
    }

    func rowAppeared(_ id: String) {
        presentRows.insert(id)
    }

    func rowDisappeared(_ id: String) {
        presentRows.remove(id)
    }

    /// The row to scroll to and highlight for `anchor`. A setting that exists only while its parent control is
    /// on (a proxy's host and port while the type is "None") has no row; its section's first shown row stands in.
    func visibleAnchor(for anchor: String) -> String {
        guard !presentRows.contains(anchor), let spec = SettingsCatalog.spec(anchor) else { return anchor }
        let parent = SettingsCatalog.all.first { $0.section == spec.section && $0.tier == .basic && presentRows.contains($0.id) }
        return parent?.id ?? anchor
    }

    func shows(_ section: SettingsSection) -> Bool {
        !section.isAdvanced || showsAdvanced || revealedSections.contains(section)
    }

    func shows(_ spec: SettingSpec) -> Bool {
        guard spec.tier.hasRow else { return false }
        if spec.section.isAdvanced { return shows(spec.section) }
        return !spec.tier.needsAdvanced || showsAdvanced || revealedSections.contains(spec.section)
    }

    /// Opens the pane (and segment) of `spec`, reveals its tier and disclosure group, then scrolls to it.
    func reveal(_ spec: SettingSpec) {
        pane = spec.pane
        if let segment = spec.section.segment { self.segment = segment }
        if spec.needsAdvanced, !showsAdvanced { revealedSections.insert(spec.section) }
        if spec.tier == .disclosure { expandedDisclosures.insert(spec.section) }
        target = SettingTarget(anchor: spec.id, pane: spec.pane)
    }

    /// Scrolls to a section of the current pane (Privacy summary links).
    func scroll(to section: SettingsSection) {
        target = SettingTarget(anchor: section.anchor, pane: section.pane)
    }

    /// Reveals every advanced section of the current pane for this session (hidden-changes footer).
    func revealAdvanced(in pane: SettingsPane, scrollingTo spec: SettingSpec?) {
        revealedSections.formUnion(SettingsSection.allCases.filter { $0.pane == pane })
        if let spec {
            if let segment = spec.section.segment { self.segment = segment }
            if spec.tier == .disclosure { expandedDisclosures.insert(spec.section) }
            target = SettingTarget(anchor: spec.id, pane: pane)
        }
    }
}
