import SwiftUI

/// Layout constants of the feature windows (Preferences, RSS, Search, Log,
/// Creator, Statistics, About, Cookies), complementing `Design`.
enum FeatureDesign {
    enum Window {
        static let statisticsMin = CGSize(width: 380, height: 470)
        static let aboutSize = CGSize(width: 600, height: 640)
        static let cookiesMin = CGSize(width: 680, height: 360)
        static let logMin = CGSize(width: 640, height: 360)
        static let creatorMin = CGSize(width: 560, height: 640)
        static let rssMin = CGSize(width: 860, height: 520)
        static let rssDownloaderMin = CGSize(width: 1_080, height: 640)
        static let searchMin = CGSize(width: 820, height: 480)
        static let sheetWidth = 460.0
        static let wideSheetWidth = 620.0
    }

    enum Width {
        /// Number fields with a stepper (ports, counts, limits).
        static let spinField = 96.0
        static let wideSpinField = 128.0
        static let narrowField = 64.0
        static let pathField = 260.0
        static let textField = 220.0
        static let picker = 220.0
        static let sidebar = 200.0
    }

    enum Palette {
        /// Execution log colors (`Log.Info`, `Log.Warning`, `Log.Critical`, `Log.TimeStamp`).
        static let logInfo = Color(light: 0x0969DA, dark: 0x58A6FF)
        static let logWarning = Color(light: 0xBC4C00, dark: 0xDB6D28)
        static let logCritical = Color(light: 0xCF222E, dark: 0xF85149)
        static let logTimestamp = Color(light: 0x6E7781, dark: 0x6E7681)
        static let pluginEnabled = Color(light: 0x1A7F37, dark: 0x3FB950)
        static let pluginDisabled = Color(light: 0xCF222E, dark: 0xF85149)
    }
}
