import SwiftUI

/// A "Use qBittorrent Neo for …" row: a checkmark once the app is the
/// default handler, otherwise a button to make it so.
struct FileAssociationRow: View {
    let title: LocalizedStringKey
    let isSet: Bool
    let makeDefault: () -> Void

    var body: some View {
        LabeledContent(title) {
            if isSet {
                Label("Default", systemImage: Symbol.checkmarkCircleFill)
                    .foregroundStyle(.green)
            } else {
                Button("Make Default", action: makeDefault)
            }
        }
    }
}
