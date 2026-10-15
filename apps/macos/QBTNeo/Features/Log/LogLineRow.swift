import SwiftUI

/// `<time> - <message>` with the timestamp and message colored like
/// qBittorrent's `Log.*` theme colors.
struct LogLineRow: View {
    let line: LogLine

    var body: some View {
        let time = Text(line.time).foregroundStyle(FeatureDesign.Palette.logTimestamp)
        let message = Text(line.text).foregroundStyle(color)
        Text("\(time) - \(message)")
            .lineLimit(4)
            .accessibilityLabel("\(levelName): \(line.text), \(line.time)")
    }

    private var color: Color {
        switch line.kind {
        case .message(.normal): .primary
        case .message(.info): FeatureDesign.Palette.logInfo
        case .message(.warning): FeatureDesign.Palette.logWarning
        case .message(.critical), .blockedPeer: FeatureDesign.Palette.logCritical
        }
    }

    private var levelName: String {
        switch line.kind {
        case .message(.normal): String(localized: "Normal")
        case .message(.info): String(localized: "Information")
        case .message(.warning): String(localized: "Warning")
        case .message(.critical): String(localized: "Critical")
        case .blockedPeer: String(localized: "Blocked peer")
        }
    }
}
