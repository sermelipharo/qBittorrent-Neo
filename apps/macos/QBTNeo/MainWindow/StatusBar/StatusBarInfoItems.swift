import SwiftUI

/// Free disk space, external IP and DHT node count (each optional).
struct StatusBarInfoItems: View {
    /// How many optional items survive at the current width: 3 keeps all,
    /// 0 drops them (drop order: DHT, then external IP, then free space).
    let level: Int
    @Environment(AppModel.self) private var model
    @Environment(GUIPreferences.self) private var gui

    var body: some View {
        let status = model.status
        if gui.statusBarFreeDiskSpace, level >= 1 {
            Label {
                Text("Free space: \(status.freeSpace >= 0 ? UnitFormatter.size(status.freeSpace) : String(localized: "N/A"))")
            } icon: {
                Image(systemName: Symbol.internaldrive)
            }
            .foregroundStyle(.secondary)
            .fixedSize()
        }
        if model.corePreferences.behavior.statusBarExternalIp, level >= 2 {
            Label {
                Text(externalIPText(status))
            } icon: {
                Image(systemName: Symbol.network)
            }
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .fixedSize()
        }
        if model.corePreferences.bittorrent.dht, level >= 3 {
            Label {
                Text("DHT: \(status.dhtNodes) nodes")
            } icon: {
                Image(systemName: Symbol.point3ConnectedTrianglepathDotted)
            }
            .foregroundStyle(.secondary)
            .fixedSize()
        }
    }

    private func externalIPText(_ status: SessionStatus) -> String {
        switch (status.externalIPv4.isEmpty, status.externalIPv6.isEmpty) {
        case (true, true): String(localized: "External IP: N/A")
        case (false, false): String(localized: "External IPs: \(status.externalIPv4), \(status.externalIPv6)")
        default: String(localized: "External IP: \(status.externalIPv4)\(status.externalIPv6)")
        }
    }
}
