import Foundation

/// `GUI/StartUpWindowState` (Hidden is not offered on macOS).
enum StartupWindowState: Int, CaseIterable, Identifiable, Sendable {
    case normal = 0
    case minimized = 1

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .normal: String(localized: "Normal")
        case .minimized: String(localized: "Minimized")
        }
    }
}
