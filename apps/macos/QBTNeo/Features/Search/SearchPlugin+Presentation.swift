import SwiftUI

extension SearchPlugin: Identifiable {
    public var id: String { name }

    /// Row color in the plugins dialog: green when enabled, red otherwise.
    var searchStatusColor: Color {
        enabled ? FeatureDesign.Palette.pluginEnabled : FeatureDesign.Palette.pluginDisabled
    }
}
