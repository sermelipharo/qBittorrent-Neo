import SwiftUI

/// "List of whitelisted IP subnets" (features.md §3.19).
struct TrustedSubnetsSheet: View {
    let subnets: [String]
    let save: ([String]) -> Void

    var body: some View {
        AddressListSheet(
            title: "List of whitelisted IP subnets", prompt: String(localized: "Example: 172.17.32.0/24, fdff:ffff:c8::/40"),
            addTitle: "Add subnet", normalize: IPAddressParser.normalizedSubnet,
            invalidMessage: String(localized: "The entered subnet is invalid."),
            duplicateMessage: String(localized: "The entered subnet is already in the list."),
            initial: subnets, save: save
        )
    }
}
