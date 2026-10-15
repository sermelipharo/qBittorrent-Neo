import Foundation

/// Display text of each transfer-list column (features.md §1.6.1), including
/// the "Hide zero and infinity values" rules.
@MainActor
enum TransferCellText {
    static func text(_ column: TransferColumn, _ item: TorrentItem, hideZero: Bool) -> String {
        switch column {
        case .queuePosition:
            return item.queuePosition > 0 ? item.queuePosition.formatted() : "*"
        case .name:
            return item.name
        case .size:
            return hideZero && item.size == 0 ? "" : UnitFormatter.size(item.size)
        case .totalSize:
            return UnitFormatter.size(item.totalSize)
        case .progress:
            return ValueFormatter.progress(item.progress)
        case .status:
            return item.statusText
        case .seeds:
            if hideZero, item.numSeeds == 0, item.numComplete <= 0 { return "" }
            return ValueFormatter.connectedOfTotal(item.numSeeds, item.numComplete < 0 ? item.numSeeds : item.numComplete)
        case .peers:
            if hideZero, item.numLeechs == 0, item.numIncomplete <= 0 { return "" }
            return ValueFormatter.connectedOfTotal(item.numLeechs, item.numIncomplete < 0 ? item.numLeechs : item.numIncomplete)
        case .downSpeed:
            return hideZero && item.dlSpeed == 0 ? "" : UnitFormatter.speed(item.dlSpeed)
        case .upSpeed:
            return hideZero && item.upSpeed == 0 ? "" : UnitFormatter.speed(item.upSpeed)
        case .eta:
            let infinite = item.eta < 0 || item.eta >= DurationFormatter.maxETA
            return hideZero && infinite ? "" : DurationFormatter.eta(item.eta)
        case .ratio:
            return hideZero && item.ratio == 0 ? "" : ValueFormatter.ratio(item.ratio)
        case .popularity:
            return hideZero && item.popularity == 0 ? "" : ValueFormatter.ratio(item.popularity)
        case .category:
            return item.category
        case .tags:
            return item.tags.joined(separator: ", ")
        case .addedOn:
            return ValueFormatter.date(item.addedOn)
        case .completedOn:
            return ValueFormatter.date(item.completionOn)
        case .tracker:
            return item.tracker
        case .downLimit:
            return hideZero && item.dlLimit <= 0 ? "" : UnitFormatter.limit(item.dlLimit)
        case .upLimit:
            return hideZero && item.upLimit <= 0 ? "" : UnitFormatter.limit(item.upLimit)
        case .downloaded:
            return sizeText(item.downloaded, hideZero)
        case .uploaded:
            return sizeText(item.uploaded, hideZero)
        case .sessionDownloaded:
            return sizeText(item.downloadedSession, hideZero)
        case .sessionUploaded:
            return sizeText(item.uploadedSession, hideZero)
        case .remaining:
            return sizeText(item.amountLeft, hideZero)
        case .timeActive:
            return DurationFormatter.timeActive(item.timeActive, seeding: item.seedingTime)
        case .savePath:
            return item.savePath
        case .completed:
            return sizeText(item.completed, hideZero)
        case .ratioLimit:
            return ValueFormatter.ratio(item.maxRatio)
        case .lastSeenComplete:
            return ValueFormatter.date(item.lastSeenComplete)
        case .lastActivity:
            let seconds = item.secondsSinceActivity(now: Int64(Date.now.timeIntervalSince1970))
            if hideZero, seconds < 0 || seconds >= DurationFormatter.maxETA { return "" }
            return DurationFormatter.ago(seconds)
        case .availability:
            return hideZero && item.availability == 0 ? "" : ValueFormatter.availability(item.availability)
        case .incompletePath:
            return item.downloadPath
        case .infohashV1:
            return ValueFormatter.hash(item.infohashV1)
        case .infohashV2:
            return ValueFormatter.hash(item.infohashV2)
        case .reannounceIn:
            return hideZero && item.reannounce == 0 ? "" : DurationFormatter.string(item.reannounce)
        case .isPrivate:
            if hideZero, item.isPrivate != true { return "" }
            return item.hasMetadata ? ValueFormatter.yesNo(item.isPrivate) : String(localized: "N/A")
        case .createdOn:
            return ValueFormatter.date(item.creationDate)
        }
    }

    private static func sizeText(_ bytes: Int64, _ hideZero: Bool) -> String {
        hideZero && bytes == 0 ? "" : UnitFormatter.size(bytes)
    }

    /// Columns whose full text is shown as a tooltip.
    static func hasTooltip(_ column: TransferColumn) -> Bool {
        switch column {
        case .name, .status, .category, .tags, .tracker, .savePath, .incompletePath, .infohashV1, .infohashV2: true
        default: false
        }
    }
}
