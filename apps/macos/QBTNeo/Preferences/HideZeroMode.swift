import Foundation

/// Scope of "Hide zero and infinity values" (`HideZeroComboValues`).
enum HideZeroMode: Int, CaseIterable, Identifiable, Sendable {
    case always = 0
    case stoppedTorrentsOnly = 1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .always: String(localized: "Always")
        case .stoppedTorrentsOnly: String(localized: "Stopped torrents only")
        }
    }
}
