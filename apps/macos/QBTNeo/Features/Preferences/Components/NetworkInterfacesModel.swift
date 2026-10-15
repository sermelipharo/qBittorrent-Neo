import Foundation
import Observation

/// Choices of the Advanced page's "Network interface" and "Optional IP
/// address to bind to" rows, from `networkInterfaces()` /
/// `networkInterfaceAddresses(interface:)`.
@Observable @MainActor
final class NetworkInterfacesModel {
    private(set) var interfaces: [NetworkInterface] = []
    private(set) var addresses: [String] = []

    func load(client: (any AppInfoClient)?, interface: String) async {
        guard let client else { return }
        interfaces = await CoreCall.run { client.networkInterfaces() }
        addresses = await CoreCall.run { client.networkInterfaceAddresses(interface: interface) }
    }

    /// (value, title) pairs: "Any interface", every interface, and a saved
    /// interface that no longer exists (shown by its saved name).
    func interfaceChoices(selected: String, savedName: String) -> [(value: String, title: String)] {
        var choices = [(value: "", title: String(localized: "Any interface"))]
        choices += interfaces.map { ($0.value, $0.name == $0.value ? $0.name : "\($0.name) (\($0.value))") }
        if !selected.isEmpty, !interfaces.contains(where: { $0.value == selected }) {
            choices.append((selected, savedName.isEmpty ? selected : savedName))
        }
        return choices
    }

    func addressChoices(selected: String) -> [(value: String, title: String)] {
        var choices = [
            (value: "", title: String(localized: "All addresses")),
            (value: "0.0.0.0", title: String(localized: "All IPv4 addresses")),
            (value: "::", title: String(localized: "All IPv6 addresses")),
        ]
        choices += addresses.map { ($0, $0) }
        if !selected.isEmpty, !choices.contains(where: { $0.value == selected }) {
            choices.append((selected, selected))
        }
        return choices
    }
}
