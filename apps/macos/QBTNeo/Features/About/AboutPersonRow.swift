import SwiftUI

/// One credited person: a role label with the name and, optionally, the
/// contact address qBittorrent publishes in its AUTHORS file.
struct AboutPersonRow: View {
    let role: LocalizedStringKey
    let name: String
    var email: String?

    var body: some View {
        LabeledContent(role) {
            VStack(alignment: .trailing, spacing: Design.Spacing.hairline) {
                Text(name)
                if let email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
