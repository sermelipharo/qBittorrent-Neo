import SwiftUI

/// "Add Peers" (features.md §2.5.4): one `IPv4:port` / `[IPv6]:port` per line.
struct AddPeersSheet: View {
    let ids: [String]
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        DialogContainer(title: "Add Peers", width: Design.Window.dialogWidth, onConfirm: save) {
            Text("List of peers to add (one IP per line):")
            TrackerListEditor(text: $text, minHeight: 140)
                .accessibilityLabel(Text("Peers"))
            Text("Format: IPv4:port / [IPv6]:port")
                .font(.callout)
                .foregroundStyle(.secondary)
            if let error {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(TorrentState.error.color)
            }
        }
    }

    private func save() {
        let lines = text.trimmingCharacters(in: .whitespacesAndNewlines).split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard !lines.isEmpty, !(lines.count == 1 && lines[0].isEmpty) else {
            error = String(localized: "Please type at least one peer.")
            return
        }
        if let invalid = lines.first(where: { !Self.isValidPeer($0) }) {
            error = String(localized: "The peer '\(invalid)' is invalid.")
            return
        }
        model.perform { try $0.addPeers(hashes: ids, peers: lines) }
        dismiss()
    }

    /// `PeerAddress::parse`: `[v6]:port` or `v4:port` with a non-zero port.
    static func isValidPeer(_ line: String) -> Bool {
        let host: Substring
        let port: Substring
        if line.hasPrefix("[") {
            guard let close = line.firstIndex(of: "]"), line[line.index(after: close)...].hasPrefix(":") else { return false }
            host = line[line.index(after: line.startIndex)..<close]
            port = line[line.index(close, offsetBy: 2)...]
            guard host.contains(":") else { return false }
        } else {
            let parts = line.split(separator: ":", omittingEmptySubsequences: false)
            guard parts.count == 2 else { return false }
            host = parts[0]
            port = parts[1]
            let octets = host.split(separator: ".", omittingEmptySubsequences: false)
            guard octets.count == 4, octets.allSatisfy({ UInt8($0) != nil }) else { return false }
        }
        guard let number = UInt16(port), number > 0 else { return false }
        return true
    }
}
