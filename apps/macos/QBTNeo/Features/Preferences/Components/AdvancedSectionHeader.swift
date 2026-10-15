import SwiftUI

/// "qBittorrent Section" / "libtorrent Section" header with its
/// "Open documentation" link.
struct AdvancedSectionHeader: View {
    let title: LocalizedStringKey
    let documentation: URL

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Link("Open documentation", destination: documentation)
                .font(.callout)
        }
    }
}
