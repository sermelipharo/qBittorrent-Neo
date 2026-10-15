import SwiftUI

/// Shared layout and styling constants so every window (main window, dialogs,
/// and the auxiliary windows built on top of this foundation) feels uniform.
enum Design {
    enum Spacing {
        /// Between tightly related elements (icon and label inside a cell).
        static let hairline = 2.0
        static let tight = 4.0
        static let small = 6.0
        static let regular = 8.0
        static let medium = 12.0
        static let large = 16.0
        static let xLarge = 20.0
    }

    enum Radius {
        static let small = 3.0
        static let medium = 6.0
        static let large = 10.0
    }

    enum Size {
        static let sidebarMinWidth = 190.0
        static let sidebarIdealWidth = 230.0
        static let sidebarMaxWidth = 360.0
        static let transferListMinHeight = 160.0
        static let propertiesMinHeight = 150.0
        /// Properties pane share of the detail column when the user has not resized it.
        static let propertiesDefaultFraction = 0.37
        static let propertiesTabBarHeight = 30.0
        static let statusBarHeight = 26.0
        static let pieceBarHeight = 16.0
        static let tableProgressBarHeight = 14.0
        static let speedFieldWidth = 110.0
        static let formLabelWidth = 150.0
    }

    enum Window {
        static let mainDefaultSize = CGSize(width: 1280, height: 800)
        static let mainMinSize = CGSize(width: 900, height: 560)
        static let addTorrentDefaultSize = CGSize(width: 900, height: 680)
        static let addTorrentMinSize = CGSize(width: 760, height: 520)
        static let dialogWidth = 460.0
        static let wideDialogWidth = 560.0
        static let snapshotSize = CGSize(width: 1400, height: 900)
    }

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.snappy(duration: 0.25)
    }

    enum Palette {
        /// Upload series / badges (qBittorrent graph pen `rgb(50,153,255)`).
        static let upload = Color(red: 50 / 255, green: 153 / 255, blue: 1)
        /// Download series / badges (qBittorrent graph pen `rgb(134,196,63)`).
        static let download = Color(red: 134 / 255, green: 196 / 255, blue: 63 / 255)
        static let pieceMissing = Color.secondary.opacity(0.12)
        static let piecePartial = Color.green
        static let pieceHave = Color.accentColor
        static let stickyTrackerRow = Color.secondary
    }
}
