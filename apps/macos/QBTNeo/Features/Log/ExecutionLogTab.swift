import Foundation

/// The two inner tabs of the Execution Log.
enum ExecutionLogTab: String, CaseIterable, Identifiable {
    case general
    case blockedIPs

    var id: Self { self }

    var title: String {
        switch self {
        case .general: String(localized: "General")
        case .blockedIPs: String(localized: "Blocked IPs")
        }
    }
}
