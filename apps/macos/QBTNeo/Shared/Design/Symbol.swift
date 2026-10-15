import Foundation

/// Every SF Symbol name the app uses, so a typo is a compile error instead of a blank icon.
/// Icons are SF Symbols only (the app icon, tracker/feed favicons and system file-type icons
/// are the only other images). Use as `Image(systemName: Symbol.trash)` or
/// `Label("Remove", systemImage: Symbol.trash)`.
///
/// A caseless enum of `String` constants adds no dependency and no runtime cost.
enum Symbol {
    static let antennaRadiowavesLeftAndRight = "antenna.radiowaves.left.and.right"
    static let antennaRadiowavesLeftAndRightSlash = "antenna.radiowaves.left.and.right.slash"
    static let arrowClockwise = "arrow.clockwise"
    static let arrowClockwiseCircle = "arrow.clockwise.circle"
    static let arrowDown = "arrow.down"
    static let arrowDownCircle = "arrow.down.circle"
    static let arrowDownCircleDotted = "arrow.down.circle.dotted"
    static let arrowDownCircleFill = "arrow.down.circle.fill"
    static let arrowDownDoc = "arrow.down.doc"
    static let arrowDownToLine = "arrow.down.to.line"
    static let arrowTriangle2Circlepath = "arrow.triangle.2.circlepath"
    static let arrowTrianglehead2ClockwiseRotate90 = "arrow.trianglehead.2.clockwise.rotate.90"
    static let arrowTrianglehead2ClockwiseRotate90CircleFill = "arrow.trianglehead.2.clockwise.rotate.90.circle.fill"
    static let arrowUp = "arrow.up"
    static let arrowUpArrowDownCircle = "arrow.up.arrow.down.circle"
    static let arrowUpCircle = "arrow.up.circle"
    static let arrowUpCircleFill = "arrow.up.circle.fill"
    static let arrowUpForwardApp = "arrow.up.forward.app"
    static let arrowUpToLine = "arrow.up.to.line"
    static let boltFill = "bolt.fill"
    static let chartBar = "chart.bar"
    static let chartLineUptrendXyaxis = "chart.line.uptrend.xyaxis"
    static let chartXyaxisLine = "chart.xyaxis.line"
    static let checkmark = "checkmark"
    static let checkmarkCircle = "checkmark.circle"
    static let checkmarkCircleFill = "checkmark.circle.fill"
    static let checkmarkSquareFill = "checkmark.square.fill"
    static let chevronDown = "chevron.down"
    static let chevronRight = "chevron.right"
    static let chevronUp = "chevron.up"
    static let circle = "circle"
    static let circleFill = "circle.fill"
    static let clock = "clock"
    static let clockArrowCirclepath = "clock.arrow.circlepath"
    static let clockFill = "clock.fill"
    static let cursorarrowClick2 = "cursorarrow.click.2"
    static let docBadgePlus = "doc.badge.plus"
    static let docOnDoc = "doc.on.doc"
    static let docRichtext = "doc.richtext"
    static let docText = "doc.text"
    static let dotRadiowavesUpForward = "dot.radiowaves.up.forward"
    static let ellipsisCircle = "ellipsis.circle"
    static let exclamationmarkArrowTrianglehead2ClockwiseRotate90 = "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90"
    static let exclamationmarkOctagon = "exclamationmark.octagon"
    static let exclamationmarkTriangle = "exclamationmark.triangle"
    static let exclamationmarkTriangleFill = "exclamationmark.triangle.fill"
    static let eye = "eye"
    static let eyeSlash = "eye.slash"
    static let folder = "folder"
    static let folderBadgeGearshape = "folder.badge.gearshape"
    static let folderBadgePlus = "folder.badge.plus"
    static let folderBadgeQuestionmark = "folder.badge.questionmark"
    static let folderCircleFill = "folder.circle.fill"
    static let folderFill = "folder.fill"
    static let forwardFill = "forward.fill"
    static let gearshape = "gearshape"
    static let gearshape2 = "gearshape.2"
    static let globe = "globe"
    static let handRaised = "hand.raised"
    static let info = "info"
    static let infoCircle = "info.circle"
    static let internaldrive = "internaldrive"
    static let key = "key"
    static let line3HorizontalDecrease = "line.3.horizontal.decrease"
    static let line3HorizontalDecreaseCircle = "line.3.horizontal.decrease.circle"
    static let linkBadgePlus = "link.badge.plus"
    static let listBulletRectangle = "list.bullet.rectangle"
    static let listNumber = "list.number"
    static let lock = "lock"
    static let lockFill = "lock.fill"
    static let macwindow = "macwindow"
    static let magnifyingglass = "magnifyingglass"
    static let minus = "minus"
    static let minusCircle = "minus.circle"
    static let minusSquareFill = "minus.square.fill"
    static let moonFill = "moon.fill"
    static let network = "network"
    static let networkBadgeShieldHalfFilled = "network.badge.shield.half.filled"
    static let networkSlash = "network.slash"
    static let newspaper = "newspaper"
    static let nosign = "nosign"
    static let pauseCircleFill = "pause.circle.fill"
    static let pauseFill = "pause.fill"
    static let pencil = "pencil"
    static let person2 = "person.2"
    static let personBadgePlus = "person.badge.plus"
    static let playFill = "play.fill"
    static let plus = "plus"
    static let point3ConnectedTrianglepathDotted = "point.3.connected.trianglepath.dotted"
    static let puzzlepieceExtension = "puzzlepiece.extension"
    static let safari = "safari"
    static let serverRack = "server.rack"
    static let shippingbox = "shippingbox"
    static let sliderHorizontal3 = "slider.horizontal.3"
    static let speedometer = "speedometer"
    static let square = "square"
    static let squareAndArrowUp = "square.and.arrow.up"
    static let stopFill = "stop.fill"
    static let tag = "tag"
    static let tagFill = "tag.fill"
    static let tagSlash = "tag.slash"
    static let textAlignleft = "text.alignleft"
    static let tortoise = "tortoise"
    static let tortoiseFill = "tortoise.fill"
    static let trash = "trash"
    static let trashSlash = "trash.slash"
    static let tray = "tray"
    static let trayFull = "tray.full"
    static let wandAndStars = "wand.and.stars"
    static let xmark = "xmark"
    static let xmarkCircle = "xmark.circle"
    static let xmarkOctagon = "xmark.octagon"
    static let xmarkOctagonFill = "xmark.octagon.fill"

    /// All names above, for the debug existence check.
    static let all: [String] = [
        antennaRadiowavesLeftAndRight,
        antennaRadiowavesLeftAndRightSlash,
        arrowClockwise,
        arrowClockwiseCircle,
        arrowDown,
        arrowDownCircle,
        arrowDownCircleDotted,
        arrowDownCircleFill,
        arrowDownDoc,
        arrowDownToLine,
        arrowTriangle2Circlepath,
        arrowTrianglehead2ClockwiseRotate90,
        arrowTrianglehead2ClockwiseRotate90CircleFill,
        arrowUp,
        arrowUpArrowDownCircle,
        arrowUpCircle,
        arrowUpCircleFill,
        arrowUpForwardApp,
        arrowUpToLine,
        boltFill,
        chartBar,
        chartLineUptrendXyaxis,
        chartXyaxisLine,
        checkmark,
        checkmarkCircle,
        checkmarkCircleFill,
        checkmarkSquareFill,
        chevronDown,
        chevronRight,
        chevronUp,
        circle,
        circleFill,
        clock,
        clockArrowCirclepath,
        clockFill,
        cursorarrowClick2,
        docBadgePlus,
        docOnDoc,
        docRichtext,
        docText,
        dotRadiowavesUpForward,
        ellipsisCircle,
        exclamationmarkArrowTrianglehead2ClockwiseRotate90,
        exclamationmarkOctagon,
        exclamationmarkTriangle,
        exclamationmarkTriangleFill,
        eye,
        eyeSlash,
        folder,
        folderBadgeGearshape,
        folderBadgePlus,
        folderBadgeQuestionmark,
        folderCircleFill,
        folderFill,
        forwardFill,
        gearshape,
        gearshape2,
        globe,
        handRaised,
        info,
        infoCircle,
        internaldrive,
        key,
        line3HorizontalDecrease,
        line3HorizontalDecreaseCircle,
        linkBadgePlus,
        listBulletRectangle,
        listNumber,
        lock,
        lockFill,
        macwindow,
        magnifyingglass,
        minus,
        minusCircle,
        minusSquareFill,
        moonFill,
        network,
        networkBadgeShieldHalfFilled,
        networkSlash,
        newspaper,
        nosign,
        pauseCircleFill,
        pauseFill,
        pencil,
        person2,
        personBadgePlus,
        playFill,
        plus,
        point3ConnectedTrianglepathDotted,
        puzzlepieceExtension,
        safari,
        serverRack,
        shippingbox,
        sliderHorizontal3,
        speedometer,
        square,
        squareAndArrowUp,
        stopFill,
        tag,
        tagFill,
        tagSlash,
        textAlignleft,
        tortoise,
        tortoiseFill,
        trash,
        trashSlash,
        tray,
        trayFull,
        wandAndStars,
        xmark,
        xmarkCircle,
        xmarkOctagon,
        xmarkOctagonFill,
    ]
}

#if DEBUG
import AppKit

extension Symbol {
    /// Names that do not resolve to a symbol on this OS (empty when everything is valid).
    static func missing() -> [String] {
        all.filter { NSImage(systemSymbolName: $0, accessibilityDescription: nil) == nil }
    }

    /// Logs and asserts when a name is missing; run once at launch in debug builds.
    static func verifyAll() {
        let names = missing()
        if !names.isEmpty {
            NSLog("Missing SF Symbols: %@", names.joined(separator: ", "))
            assertionFailure("Missing SF Symbols: \(names.joined(separator: ", "))")
        }
    }
}
#endif
