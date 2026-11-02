import SwiftUI

extension PluginInfo: Identifiable {
    /// Row color in the Plugins window: green when enabled, red otherwise (as in qBittorrent).
    var statusColor: Color {
        enabled ? FeatureDesign.Palette.pluginEnabled : FeatureDesign.Palette.pluginDisabled
    }

    var invocableText: String {
        invocable ? String(localized: "Yes") : String(localized: "No")
    }
}
