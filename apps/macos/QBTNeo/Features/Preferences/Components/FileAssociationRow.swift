import SwiftUI

/// A default-application row (".torrent files", "Magnet links"): a check
/// mark once qBittorrent Neo is the default handler, otherwise "Make Default".
struct FileAssociationRow: View {
    let id: String
    let isSet: Bool
    let makeDefault: () -> Void

    var body: some View {
        LabeledContent(SettingsCatalog.key(id)) {
            if isSet {
                Label {
                    Text("Default")
                } icon: {
                    Image(systemName: Symbol.checkmarkCircleFill)
                        .foregroundStyle(.green)
                }
            } else {
                Button("Make Default", action: makeDefault)
            }
        }
        .setting(id)
    }
}
