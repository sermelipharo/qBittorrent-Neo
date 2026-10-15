import Foundation

/// One entry of the settings catalog: where a setting lives, its tier, the
/// label shown in search, and the stored keys it covers.
struct SettingSpec: Identifiable {
    /// Stable anchor: the WebAPI key, the ini key, or `system.*` for macOS integration rows.
    let id: String
    let section: SettingsSection
    /// Label as shown on the row (search result title).
    let title: String
    let tier: SettingTier
    /// One-line explanation shown under the control.
    let help: String?
    /// Every stored key this row edits (WebAPI keys and GUI ini keys).
    let keys: [String]
    /// Extra search words ("VPN", "kill switch", "turtle", …).
    let keywords: [String]
    /// Whether the stored value is still the default (hidden-changes counter); nil = not tracked.
    let check: SettingCheck?

    init(
        _ id: String, _ section: SettingsSection, _ title: String, _ tier: SettingTier = .basic,
        help: String? = nil, keys: [String]? = nil, keywords: [String] = [], check: SettingCheck? = nil
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.tier = tier
        self.help = help
        self.keys = keys ?? (id.hasPrefix("system.") ? [] : [id])
        self.keywords = keywords
        self.check = check
    }

    var pane: SettingsPane { section.pane }

    /// Visible only with "Show advanced settings" (the row's tier or its section's).
    var needsAdvanced: Bool { tier.needsAdvanced || section.isAdvanced }
}
