import SwiftUI

/// A checkbox over several torrents' values: mixed (dash) while they differ,
/// one shared value once the user clicks it.
struct TriStateToggle: View {
    let title: LocalizedStringKey
    /// One value per selected torrent.
    @Binding var values: [Bool]

    var body: some View {
        Toggle(title, sources: $values, isOn: \.self)
    }
}
