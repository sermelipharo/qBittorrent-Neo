import Foundation

/// Speed tab period combo (`SpeedWidget/period`, default index 1).
enum SpeedGraphPeriod: Int, CaseIterable, Identifiable, Sendable {
    case minute1 = 0
    case minutes5 = 1
    case minutes30 = 2
    case hours3 = 3
    case hours6 = 4
    case hours12 = 5
    case hours24 = 6

    var id: Int { rawValue }

    var seconds: UInt32 {
        switch self {
        case .minute1: 60
        case .minutes5: 300
        case .minutes30: 1800
        case .hours3: 10_800
        case .hours6: 21_600
        case .hours12: 43_200
        case .hours24: 86_400
        }
    }

    /// Averaging resolution of qBittorrent's matching averager, in seconds.
    var resolution: Int {
        switch self {
        case .minute1, .minutes5: 1
        case .minutes30: 6
        case .hours3, .hours6: 36
        case .hours12: 72
        case .hours24: 144
        }
    }

    var title: String {
        switch self {
        case .minute1: String(localized: "1 Minute")
        case .minutes5: String(localized: "5 Minutes")
        case .minutes30: String(localized: "30 Minutes")
        case .hours3: String(localized: "3 Hours")
        case .hours6: String(localized: "6 Hours")
        case .hours12: String(localized: "12 Hours")
        case .hours24: String(localized: "24 Hours")
        }
    }
}
