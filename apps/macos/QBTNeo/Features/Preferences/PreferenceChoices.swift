import Foundation

/// Picker items (in qBittorrent's combo order) and their labels for the
/// core enums used on the Settings pages.
enum PreferenceChoices {
    static let contentLayouts: [ContentLayout] = [.original, .subfolder, .noSubfolder]
    static let stopConditions: [StopCondition] = [.none, .metadataReceived, .filesChecked]
    static let proxyTypes: [ProxyType] = [.none, .socks4, .socks5, .http]
    static let schedulerDays: [SchedulerDays] = [
        .everyDay, .weekday, .weekend, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday,
    ]
    static let encryptionModes: [EncryptionMode] = [.allow, .require, .disable]
    /// "then" combo: the GUI index differs from the enum value.
    static let shareLimitActions: [ShareLimitAction] = [.stop, .remove, .removeWithContent, .enableSuperSeeding]
    static let fileLogAgeTypes: [FileLogAgeType] = [.days, .months, .years]
    static let protocols: [BtProtocol] = [.both, .tcp, .utp]
    static let dynDNSServices: [DynDnsService] = [.dynDns, .noIp]

    static func title(_ value: ContentLayout) -> String {
        switch value {
        case .original: String(localized: "Original")
        case .subfolder: String(localized: "Create subfolder")
        case .noSubfolder: String(localized: "Don't create subfolder")
        }
    }

    static func title(_ value: StopCondition) -> String {
        switch value {
        case .none: String(localized: "None")
        case .metadataReceived: String(localized: "Metadata received")
        case .filesChecked: String(localized: "Files checked")
        }
    }

    static func title(_ value: ProxyType) -> String {
        switch value {
        case .none: String(localized: "(None)")
        case .socks4: "SOCKS4"
        case .socks5: "SOCKS5"
        case .http: "HTTP"
        }
    }

    static func title(_ value: SchedulerDays) -> String {
        switch value {
        case .everyDay: String(localized: "Every day")
        case .weekday: String(localized: "Weekdays")
        case .weekend: String(localized: "Weekends")
        default: weekdayName(value)
        }
    }

    /// Localized full weekday names, Monday first.
    private static func weekdayName(_ value: SchedulerDays) -> String {
        let order: [SchedulerDays] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        let names = Calendar.current.standaloneWeekdaySymbols
        guard let index = order.firstIndex(of: value), names.indices.contains(index) else { return "" }
        return names[index]
    }

    static func title(_ value: EncryptionMode) -> String {
        switch value {
        case .allow: String(localized: "Allow encryption")
        case .require: String(localized: "Require encryption")
        case .disable: String(localized: "Disable encryption")
        }
    }

    static func title(_ value: ShareLimitAction) -> String {
        switch value {
        case .default: String(localized: "Default")
        case .stop: String(localized: "Stop torrent")
        case .remove: String(localized: "Remove torrent")
        case .removeWithContent: String(localized: "Remove torrent and its files")
        case .enableSuperSeeding: String(localized: "Enable super seeding for torrent")
        }
    }

    static func title(_ value: FileLogAgeType) -> String {
        switch value {
        case .days: String(localized: "days")
        case .months: String(localized: "months")
        case .years: String(localized: "years")
        }
    }

    static func title(_ value: BtProtocol) -> String {
        switch value {
        case .both: String(localized: "TCP and μTP")
        case .tcp: "TCP"
        case .utp: "μTP"
        }
    }

    static func title(_ value: DynDnsService) -> String {
        switch value {
        case .dynDns: "DynDNS"
        case .noIp: "No-IP"
        }
    }
}
