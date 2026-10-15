import SwiftUI

/// A third-party component: linked name, its authors and its license.
struct AboutComponentRow: View {
    let name: String
    let author: LocalizedStringKey
    let license: String
    let url: URL

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.hairline) {
            Link(name, destination: url)
            Text("\(Text(author)) · \(license)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
