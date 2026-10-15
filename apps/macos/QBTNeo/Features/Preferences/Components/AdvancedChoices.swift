import Foundation

/// Combo items of the Advanced page.
enum AdvancedChoices {
    static let resumeStorage: [ResumeDataStorageType] = [.legacy, .sqLite]
    static let removeOptions: [ContentRemoveOption] = [.delete, .moveToTrash]
    static let diskIOTypes: [DiskIoType] = [.default, .mMap, .posix, .simplePreadPwrite]
    static let readModes: [DiskIoReadMode] = [.disableOsCache, .enableOsCache]
    static let writeModes: [DiskIoWriteMode] = [.disableOsCache, .enableOsCache, .writeThrough]
    static let mixedModes: [UtpMixedMode] = [.preferTcp, .peerProportional]
    static let slotBehaviors: [UploadSlotsBehavior] = [.fixedSlots, .rateBased]
    static let chokingAlgorithms: [UploadChokingAlgorithm] = [.roundRobin, .fastestUpload, .antiLeech]

    static func title(_ value: ResumeDataStorageType) -> String {
        switch value {
        case .legacy: String(localized: "Fastresume files")
        case .sqLite: String(localized: "SQLite database (experimental)")
        }
    }

    static func title(_ value: ContentRemoveOption) -> String {
        switch value {
        case .delete: String(localized: "Delete files permanently")
        case .moveToTrash: String(localized: "Move files to trash (if possible)")
        }
    }

    static func title(_ value: DiskIoType) -> String {
        switch value {
        case .default: String(localized: "Default")
        case .mMap: String(localized: "Memory mapped files")
        case .posix: String(localized: "POSIX-compliant")
        case .simplePreadPwrite: String(localized: "Simple pread/pwrite")
        }
    }

    static func title(_ value: DiskIoReadMode) -> String {
        switch value {
        case .disableOsCache: String(localized: "Disable OS cache")
        case .enableOsCache: String(localized: "Enable OS cache")
        }
    }

    static func title(_ value: DiskIoWriteMode) -> String {
        switch value {
        case .disableOsCache: String(localized: "Disable OS cache")
        case .enableOsCache: String(localized: "Enable OS cache")
        case .writeThrough: String(localized: "Write-through")
        }
    }

    static func title(_ value: UtpMixedMode) -> String {
        switch value {
        case .preferTcp: String(localized: "Prefer TCP")
        case .peerProportional: String(localized: "Peer proportional (throttles TCP)")
        }
    }

    static func title(_ value: UploadSlotsBehavior) -> String {
        switch value {
        case .fixedSlots: String(localized: "Fixed slots")
        case .rateBased: String(localized: "Upload rate based")
        }
    }

    static func title(_ value: UploadChokingAlgorithm) -> String {
        switch value {
        case .roundRobin: String(localized: "Round-robin")
        case .fastestUpload: String(localized: "Fastest upload")
        case .antiLeech: String(localized: "Anti-leech")
        }
    }
}
