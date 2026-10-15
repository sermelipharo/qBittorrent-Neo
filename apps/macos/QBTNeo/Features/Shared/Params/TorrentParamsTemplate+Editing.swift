import Foundation

/// Editor-friendly views of `TorrentParamsTemplate` fields (watched folder
/// options, RSS download rules).
extension TorrentParamsTemplate {
    /// "Start torrent:" Default / Yes / No (stored inverted as `stopped`).
    var editorStartTorrent: Bool? {
        get { stopped.map { !$0 } }
        set { stopped = newValue.map { !$0 } }
    }

    var editorRatioMode: ParamsLimitMode {
        get { ParamsLimitMode(ratioLimit) }
        set { ratioLimit = newValue.raw(current: ratioLimit, initial: 1) }
    }

    var editorRatioValue: Double {
        get { ratioLimit >= 0 ? ratioLimit : 1 }
        set { ratioLimit = max(newValue, 0) }
    }

    var editorSeedingTimeMode: ParamsLimitMode {
        get { ParamsLimitMode(seedingTimeLimit) }
        set { seedingTimeLimit = newValue.raw(current: seedingTimeLimit, initial: 1_440) }
    }

    var editorSeedingTimeValue: Int64 {
        get { seedingTimeLimit >= 0 ? seedingTimeLimit : 1_440 }
        set { seedingTimeLimit = max(newValue, 0) }
    }

    var editorInactiveTimeMode: ParamsLimitMode {
        get { ParamsLimitMode(inactiveSeedingTimeLimit) }
        set { inactiveSeedingTimeLimit = newValue.raw(current: inactiveSeedingTimeLimit, initial: 1_440) }
    }

    var editorInactiveTimeValue: Int64 {
        get { inactiveSeedingTimeLimit >= 0 ? inactiveSeedingTimeLimit : 1_440 }
        set { inactiveSeedingTimeLimit = max(newValue, 0) }
    }
}
