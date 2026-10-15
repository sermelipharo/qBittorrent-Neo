import SwiftUI

/// "List of banned IP addresses" (features.md §3.18).
struct BannedIPsSheet: View {
    let addresses: [String]
    let save: ([String]) -> Void

    var body: some View {
        AddressListSheet(
            title: "List of banned IP addresses", prompt: "203.0.113.7", addTitle: "Ban IP",
            normalize: IPAddressParser.normalizedAddress,
            invalidMessage: String(localized: "The entered IP address is invalid."),
            duplicateMessage: String(localized: "The entered IP is already banned."),
            initial: addresses, save: save
        )
    }
}
