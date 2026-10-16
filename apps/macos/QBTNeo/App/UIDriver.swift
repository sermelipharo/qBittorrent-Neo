#if DEBUG
import AppKit

/// In-process UI driver for end-to-end verification without Accessibility
/// permission. Controls are located through the app's own accessibility tree
/// and driven with synthesized `NSEvent`s delivered to the app's windows, so
/// they take the normal AppKit/SwiftUI event path like real clicks and typing.
/// Compiled in DEBUG only; activated by `QBT_UI_SCRIPT=<scenario>`.
@MainActor
final class UIDriver {
    struct Element {
        let object: NSObject
        let window: NSWindow
        let role: String
        let label: String
        let identifier: String
        let value: String
        let frame: NSRect
        let enabled: Bool

        var description: String {
            let box = "\(Int(frame.minX)),\(Int(frame.minY)),\(Int(frame.width))x\(Int(frame.height))"
            return "\(role) label='\(label)' id='\(identifier)' value='\(value)' enabled=\(enabled) frame=\(box)"
        }
    }

    struct Failure: Error, CustomStringConvertible {
        let description: String
    }

    let model: AppModel
    private let directory: String
    private var eventNumber = 1

    init(model: AppModel) {
        self.model = model
        directory = ProcessInfo.processInfo.environment["QBT_UI_DIR"] ?? NSTemporaryDirectory()
        // SwiftUI builds its accessibility elements only once an assistive client asks for them; this is what such a
        // client sets on the application (without it, hosting views expose almost no labelled controls).
        _ = NSApp.perform(NSSelectorFromString("accessibilitySetValue:forAttribute:"), with: NSNumber(value: true),
                          with: "AXEnhancedUserInterface" as NSString)
    }

    // MARK: Logging and assertions

    func log(_ text: String) {
        FileHandle.standardError.write(Data("UIDRIVER: \(text)\n".utf8))
    }

    func check(_ condition: Bool, _ text: String) {
        log((condition ? "PASS: " : "FAIL: ") + text)
    }

    /// Asks the external watcher to capture this process' windows, then waits for its ack.
    func shot(_ name: String) async {
        let request = "\(directory)/shot-\(name).req"
        let ack = "\(directory)/shot-\(name).ack"
        try? FileManager.default.removeItem(atPath: ack)
        try? "\(ProcessInfo.processInfo.processIdentifier)".write(toFile: request, atomically: true, encoding: .utf8)
        log("SHOT \(name)")
        Self.setHidden(false)
        _ = await wait(timeout: 25) { FileManager.default.fileExists(atPath: ack) }
        Self.setHidden(true)
    }

    /// While a scenario runs, windows are kept practically invisible and click-through so the user's
    /// work is never covered; they are shown (still behind the active app) only while captured.
    static var hidesWindows = false
    private static var capturing = false

    static func setHidden(_ hidden: Bool) {
        guard hidesWindows else { return }
        capturing = !hidden
        applyHiding()
    }

    /// `QBT_UI_VISIBLE=1`, or a file named `visible` in the control directory (polled, so a running scenario
    /// can be switched without a restart: create the file to show the windows, delete it to hide them again).
    static var wantsVisibleWindows: Bool {
        if ProcessInfo.processInfo.environment["QBT_UI_VISIBLE"] == "1" { return true }
        guard let directory = ProcessInfo.processInfo.environment["QBT_UI_DIR"] else { return false }
        return FileManager.default.fileExists(atPath: directory + "/visible")
    }

    /// Applies the hidden/capture state to every window (also called for windows opened later).
    static func applyHiding() {
        guard hidesWindows else { return }
        let visible = wantsVisibleWindows
        for window in NSApp.windows where !(window is NSPanel) || window.isVisible {
            let alpha: CGFloat = capturing || visible ? 1 : 0.01
            if window.alphaValue != alpha { window.alphaValue = alpha }
            // Visible mode: normal opacity and level, mouse events enabled; the app is still never activated.
            if window.ignoresMouseEvents != !visible { window.ignoresMouseEvents = !visible }
            // Hidden windows are otherwise laid out lazily; keep the SwiftUI content current.
            window.contentView?.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
        }
    }

    /// Fire-and-forget capture request (the external watcher captures within a fraction of a second);
    /// usable from timers while a modal loop runs.
    func requestShotNow(_ name: String) {
        let request = "\(directory)/shot-\(name).req"
        try? "\(ProcessInfo.processInfo.processIdentifier)".write(toFile: request, atomically: true, encoding: .utf8)
        log("SHOT \(name)")
    }

    func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    func wait(timeout: Double = 15, _ condition: () -> Bool) async -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if condition() { return true }
            await pause(0.1)
        }
        return condition()
    }

    // MARK: Accessibility tree

    private func string(_ object: NSObject, _ selector: String) -> String {
        guard object.responds(to: NSSelectorFromString(selector)),
              let value = object.perform(NSSelectorFromString(selector))?.takeUnretainedValue() else { return "" }
        if let text = value as? String { return text }
        return "\(value)"
    }

    func frame(of object: NSObject) -> NSRect {
        guard object.responds(to: NSSelectorFromString("accessibilityFrame")), let value = object.value(forKey: "accessibilityFrame") as? NSValue
        else { return .zero }
        return value.rectValue
    }

    func children(of object: NSObject) -> [NSObject] {
        var result: [NSObject] = []
        if object.responds(to: NSSelectorFromString("accessibilityChildren")),
           let list = object.perform(NSSelectorFromString("accessibilityChildren"))?.takeUnretainedValue() as? [Any] {
            result = list.compactMap { $0 as? NSObject }
        }
        if result.isEmpty, let view = object as? NSView {
            result = view.subviews
        }
        return result
    }

    func element(_ object: NSObject, in window: NSWindow) -> Element {
        Element(
            object: object, window: window,
            role: string(object, "accessibilityRole"), label: string(object, "accessibilityLabel"),
            identifier: string(object, "accessibilityIdentifier"),
            value: string(object, "accessibilityValue"), frame: frame(of: object),
            enabled: object.responds(to: NSSelectorFromString("isAccessibilityEnabled"))
                ? (object.value(forKey: "accessibilityEnabled") as? Bool ?? true) : true
        )
    }

    /// Every element of the window (depth first), including the content view's AppKit subviews.
    func elements(in window: NSWindow, limit: Int = 4000) -> [Element] {
        var result: [Element] = []
        var seen = Set<ObjectIdentifier>()
        func visit(_ object: NSObject, depth: Int) {
            guard result.count < limit, depth < 60, seen.insert(ObjectIdentifier(object)).inserted else { return }
            result.append(element(object, in: window))
            for child in children(of: object) { visit(child, depth: depth + 1) }
        }
        if let content = window.contentView { visit(content, depth: 0) }
        return result
    }

    /// Visible windows, frontmost first (sheets before their parents).
    var windows: [NSWindow] {
        // Alert panels shown as sheets of the main window are not always in the ordered list.
        let ordered = NSApp.orderedWindows.filter(\.isVisible)
        let extra = NSApp.windows.filter { $0.isVisible && $0 is NSPanel && !ordered.contains($0) }
        return ordered + extra
    }

    func window(titled title: String) -> NSWindow? {
        windows.first { $0.title == title || $0.title.contains(title) }
    }

    func dump(_ window: NSWindow, maxLines: Int = 400) {
        log("--- AX dump of '\(window.title)' (\(window.frame)) sheet=\(window.isSheet)")
        for (index, element) in elements(in: window).prefix(maxLines).enumerated() {
            log("  [\(index)] \(element.object.className) \(element.description)")
        }
    }

    /// Elements matching role/label/identifier in the given windows (default: all visible).
    func find(role: String? = nil, label: String? = nil, labelContains: String? = nil, identifier: String? = nil,
              in scope: [NSWindow]? = nil) -> [Element] {
        var matches: [Element] = []
        for window in scope ?? windows {
            for element in elements(in: window) {
                if let role, element.role != role { continue }
                if let label, element.label != label { continue }
                if let labelContains, !element.label.localizedCaseInsensitiveContains(labelContains) { continue }
                if let identifier, element.identifier != identifier { continue }
                guard element.frame.width > 0, element.frame.height > 0 else { continue }
                matches.append(element)
            }
        }
        return matches
    }

    /// The first match once its frame has stopped changing and it is enabled.
    func settled(role: String? = nil, label: String? = nil, timeout: Double = 10) async -> Element? {
        var last: NSRect?
        var stableSince = Date()
        var result: Element?
        _ = await wait(timeout: timeout) {
            guard let current = find(role: role, label: label).first else { return false }
            if current.frame != last { last = current.frame; stableSince = Date() }
            result = current
            return current.enabled && Date().timeIntervalSince(stableSince) > 0.6
        }
        return result
    }

    func require(role: String? = nil, label: String? = nil, labelContains: String? = nil, identifier: String? = nil,
                 in scope: [NSWindow]? = nil, timeout: Double = 10) async throws -> Element {
        var found: Element?
        _ = await wait(timeout: timeout) {
            found = find(role: role, label: label, labelContains: labelContains, identifier: identifier, in: scope).first
            return found != nil
        }
        guard let found else {
            for window in NSApp.windows {
                log("window \(Swift.type(of: window)) '\(window.title)' visible=\(window.isVisible) frame=\(window.frame)")
            }
            if ProcessInfo.processInfo.environment["QBT_UI_DUMP"] == "1" {
                for window in windows where !(window is NSPanel) { dump(window, maxLines: 120) }
            }
            throw Failure(description: "element not found role=\(role ?? "*") label=\(label ?? labelContains ?? "*") id=\(identifier ?? "*")")
        }
        return found
    }

    /// Makes `window` the key window of this app without activating the app (the user's frontmost
    /// application is never disturbed); events are delivered to the window directly either way.
    func ensureKey(_ window: NSWindow) async {
        if !window.isKeyWindow { window.makeKey() }
    }

    // MARK: Views

    func staticTexts(under root: NSObject, in window: NSWindow, depth: Int = 0) -> [String] {
        guard depth < 12 else { return [] }
        let item = element(root, in: window)
        var texts = item.role == "AXStaticText" && !item.value.isEmpty ? [item.value] : []
        for child in children(of: root) { texts += staticTexts(under: child, in: window, depth: depth + 1) }
        return texts
    }

    /// Visible text of each cell of a table (row-major), read from the cells' accessibility static texts.
    func tableTexts(_ table: NSTableView) -> [[String]] {
        guard let window = table.window else { return [] }
        return (0 ..< table.numberOfRows).map { row in
            (0 ..< table.numberOfColumns).map { column in
                guard let cell = table.view(atColumn: column, row: row, makeIfNecessary: true) else { return "" }
                let texts = staticTexts(under: cell, in: window)
                return texts.joined(separator: " ")
            }
        }
    }

    func views(in window: NSWindow, classNameContains name: String) -> [NSView] {
        var result: [NSView] = []
        func visit(_ view: NSView) {
            if String(describing: Swift.type(of: view)).contains(name) { result.append(view) }
            for sub in view.subviews { visit(sub) }
        }
        if let content = window.contentView?.superview ?? window.contentView { visit(content) }
        return result
    }

    /// Left-clicks the row `row` of a table view at `xOffset` points from its left edge.
    func clickRow(_ table: NSTableView, row: Int, xOffset: CGFloat = 80) async {
        guard let window = table.window else { return }
        await ensureKey(window)
        table.scrollRowToVisible(row)
        await pause(0.2)
        let rect = table.rect(ofRow: row)
        let location = table.convert(NSPoint(x: rect.minX + xOffset, y: rect.midY), to: nil)
        let state = "active=\(NSApp.isActive) key=\(window.isKeyWindow)"
        log("CLICK table row \(row) at window point \(Int(location.x)),\(Int(location.y)) in '\(window.title)' \(state)")
        // A table's mouseDown tracks until the mouse-up arrives, so the up goes to the queue first.
        if let up = mouse(.leftMouseUp, at: location, in: window) { NSApp.postEvent(up, atStart: false) }
        if let root = window.contentView?.superview, let view = root.hitTest(location) {
            log("hit view \(Swift.type(of: view)) isTable=\(view === table)")
        }
        // Inactive app: the window would swallow the first click, so the table gets the event itself.
        if window.isKeyWindow {
            deliver(.leftMouseDown, at: location, in: window)
        } else if let down = mouse(.leftMouseDown, at: location, in: window) {
            table.mouseDown(with: down)
        }
        await pause(0.5)
        if table.selectedRow != row {
            // A table of an inactive app ignores synthesized clicks; select through the table's own API,
            // which notifies SwiftUI's selection binding exactly like a click.
            log("click did not select row \(row) (inactive app); selecting through NSTableView")
            table.selectRowIndexes([row], byExtendingSelection: false)
            await pause(0.4)
        }
        log("table selectedRow=\(table.selectedRow)")
    }

    /// Delivers a mouse event. A key window gets it through `sendEvent` (the whole AppKit path); a window of
    /// an inactive app would swallow the first click to activate, so the event goes to the hit-tested view.
    private func deliver(_ type: NSEvent.EventType, at location: NSPoint, in window: NSWindow, clicks: Int = 1, direct: Bool = false) {
        guard let event = mouse(type, at: location, in: window, clicks: clicks) else { return }
        guard direct, !window.isKeyWindow, let root = window.contentView?.superview, let view = root.hitTest(location) else {
            window.sendEvent(event)
            return
        }
        switch type {
        case .leftMouseDown: view.mouseDown(with: event)
        case .leftMouseUp: view.mouseUp(with: event)
        case .rightMouseDown: view.rightMouseDown(with: event)
        case .rightMouseUp: view.rightMouseUp(with: event)
        default: window.sendEvent(event)
        }
    }

    // MARK: Context menus

    /// Builds the row's real context menu the way a right mouse-down does (`menu(for:)` up the hit view's
    /// superview chain), logs its items and activates the one titled `title` like a user choosing it. Used
    /// where the popup itself cannot be driven (the tracking loop does not open for synthesized events).
    func contextMenuPerform(table: NSTableView, row: Int, title: String) async -> Bool {
        await contextMenuPerform(table: table, row: row, path: [title])
    }

    /// Like `contextMenuPerform(table:row:title:)`, following submenu titles: `["Priority", "High"]`.
    func contextMenuPerform(table: NSTableView, row: Int, path: [String]) async -> Bool {
        guard let window = table.window else { return false }
        await ensureKey(window)
        let rect = table.rect(ofRow: row)
        let location = table.convert(NSPoint(x: rect.minX + 80, y: rect.midY), to: nil)
        guard let event = mouse(.rightMouseDown, at: location, in: window),
              var view = window.contentView?.superview?.hitTest(location) else { return false }
        var found: NSMenu?
        while found == nil {
            found = view.menu(for: event)
            guard found == nil, let parent = view.superview else { break }
            view = parent
        }
        guard var menu = found else {
            log("no context menu for row \(row)")
            return false
        }
        log("CONTEXT MENU of row \(row): " + Self.menuSummary(menu))
        for (depth, title) in path.enumerated() {
            guard let index = menu.items.firstIndex(where: { $0.title == title }), menu.items[index].isEnabled else {
                log("context menu item '\(title)' missing or disabled")
                return false
            }
            if depth == path.count - 1 {
                log("CHOOSE context menu item '\(path.joined(separator: " > "))'")
                menu.performActionForItem(at: index)
            } else if let submenu = menu.items[index].submenu {
                log("SUBMENU '\(title)': " + Self.menuSummary(submenu))
                menu = submenu
            } else {
                log("context menu item '\(title)' has no submenu")
                return false
            }
        }
        await pause(0.8)
        return true
    }

    static func menuSummary(_ menu: NSMenu) -> String {
        menu.items.map { item in
            item.isSeparatorItem ? "-" : item.title + (item.state == .on ? " [on]" : "") + (item.isEnabled ? "" : " (disabled)")
        }.joined(separator: " | ")
    }

    // MARK: Events

    private func nextNumber() -> Int {
        eventNumber += 1
        return eventNumber
    }

    func mouse(_ type: NSEvent.EventType, at point: NSPoint, in window: NSWindow, modifiers: NSEvent.ModifierFlags = [],
               clicks: Int = 1) -> NSEvent? {
        NSEvent.mouseEvent(
            with: type, location: point, modifierFlags: modifiers, timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, eventNumber: nextNumber(), clickCount: clicks,
            pressure: type == .leftMouseUp || type == .rightMouseUp ? 0 : 1
        )
    }

    /// Window-space point for the centre of `frame` (screen coordinates), nudged by `offset`.
    func point(in window: NSWindow, frame: NSRect, offset: NSPoint = .zero) -> NSPoint {
        window.convertPoint(fromScreen: NSPoint(x: frame.midX + offset.x, y: frame.midY + offset.y))
    }

    func click(_ element: Element, offset: NSPoint = .zero, clicks: Int = 1) async {
        let window = element.window
        await ensureKey(window)
        var frame = self.frame(of: element.object)
        if frame.isEmpty { frame = element.frame }
        let location = point(in: window, frame: frame, offset: offset)
        let state = "active=\(NSApp.isActive) key=\(window.isKeyWindow)"
        log("CLICK \(element.role) '\(element.label)' at \(Int(location.x)),\(Int(location.y)) in '\(window.title)' \(state)")
        for count in 1 ... clicks {
            deliver(.leftMouseDown, at: location, in: window, clicks: count)
            await pause(0.05)
            deliver(.leftMouseUp, at: location, in: window, clicks: count)
            await pause(0.1)
        }
        await pause(0.4)
    }

    /// Click on an element where the mouse events go straight to the hit-tested view (inactive app, non-key window).
    func clickDirect(_ element: Element) async {
        let window = element.window
        var frame = self.frame(of: element.object)
        if frame.isEmpty { frame = element.frame }
        let location = point(in: window, frame: frame)
        let hit = window.contentView?.superview?.hitTest(location)
        let hitName = hit.map { String(describing: Swift.type(of: $0)) } ?? "nil"
        log("CLICK(direct) \(element.role) '\(element.label)' hit view \(hitName) at \(Int(location.x)),\(Int(location.y))")
        deliver(.leftMouseDown, at: location, in: window, direct: true)
        await pause(0.05)
        deliver(.leftMouseUp, at: location, in: window, direct: true)
        await pause(0.5)
    }

    /// Clicks the centre of an arbitrary view (a toolbar button) with a synthesized mouse down and up.
    func clickView(_ view: NSView, in window: NSWindow) async {
        await ensureKey(window)
        let location = view.convert(NSPoint(x: view.bounds.midX, y: view.bounds.midY), to: nil)
        log("CLICK view \(Swift.type(of: view)) at \(Int(location.x)),\(Int(location.y)) in '\(window.title)'")
        deliver(.leftMouseDown, at: location, in: window)
        await pause(0.05)
        deliver(.leftMouseUp, at: location, in: window)
        await pause(0.3)
    }

    static let keyCodes: [Character: UInt16] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
        "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23, "9": 25, "7": 26, "8": 28, "0": 29, "o": 31,
        "u": 32, "i": 34, "p": 35, "l": 37, "j": 38, "k": 40, "n": 45, "m": 46, " ": 49,
    ]

    static let punctuationKeys: [Character: UInt16] = [
        ".": 47, "/": 44, "-": 27, "=": 24, ",": 43, ";": 41, "'": 39, "[": 33, "]": 30, "\\": 42,
    ]
    /// Shifted symbols: the unshifted key they share.
    static let shiftedKeys: [Character: Character] = [
        "?": "/", "&": "7", "%": "5", ":": ";", "+": "=", "_": "-", "!": "1", "@": "2", "#": "3", "$": "4", "^": "6", "*": "8",
        "(": "9", ")": "0", "\"": "'", "<": ",", ">": ".", "{": "[", "}": "]", "|": "\\", "~": "`",
    ]

    /// One key press (down + up) delivered to the window; Command shortcuts go through the menus as
    /// `NSApplication.sendEvent` would. Synchronous, so it also works inside modal run loops.
    func keyNow(_ characters: String, code: UInt16? = nil, modifiers: NSEvent.ModifierFlags = [], window: NSWindow? = nil,
                ignoring: String? = nil) {
        let target = window ?? NSApp.modalWindow ?? NSApp.keyWindow ?? NSApp.mainWindow ?? windows.first
        let number = target?.windowNumber ?? 0
        let keyCode = code ?? characters.lowercased().first.flatMap { Self.keyCodes[$0] } ?? 0
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            guard let event = NSEvent.keyEvent(
                with: type, location: .zero, modifierFlags: modifiers, timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: number, context: nil, characters: characters, charactersIgnoringModifiers: ignoring ?? characters.lowercased(),
                isARepeat: false, keyCode: keyCode
            ) else { continue }
            if modifiers.contains(.command) {
                if type == .keyDown, target?.performKeyEquivalent(with: event) != true { _ = NSApp.mainMenu?.performKeyEquivalent(with: event) }
            } else if type == .keyDown, characters == "\r" || characters == "\u{1b}", target?.performKeyEquivalent(with: event) == true {
                // Return / Escape on a button's key equivalent (an inactive window skips this step in sendEvent).
                continue
            } else {
                target?.sendEvent(event)
            }
        }
    }

    func key(_ characters: String, code: UInt16? = nil, modifiers: NSEvent.ModifierFlags = [], window: NSWindow? = nil) async {
        keyNow(characters, code: code, modifiers: modifiers, window: window)
        await pause(0.2)
    }

    /// Synchronous click on an element's current frame (for modal run loops).
    func clickNow(_ element: Element) {
        let window = element.window
        var frame = self.frame(of: element.object)
        if frame.isEmpty { frame = element.frame }
        let location = point(in: window, frame: frame)
        log("CLICK(modal) \(element.role) '\(element.label)' at \(Int(location.x)),\(Int(location.y)) in '\(window.title)'")
        deliver(.leftMouseDown, at: location, in: window)
        deliver(.leftMouseUp, at: location, in: window)
    }

    func typeNow(_ text: String, window: NSWindow? = nil) {
        log("TYPE(modal) \(text.count) characters")
        for character in text { keyNow(String(character), window: window) }
    }

    /// Runs `body` after `delay` seconds from a run-loop timer in the common modes. Unlike Swift tasks these
    /// also fire while a modal alert or menu is running its own event loop.
    func afterCommon(_ delay: Double, _ body: @escaping @MainActor () -> Void) {
        let timer = Timer(timeInterval: delay, repeats: false) { _ in
            MainActor.assumeIsolated { body() }
        }
        RunLoop.main.add(timer, forMode: .common)
        RunLoop.main.add(timer, forMode: .modalPanel)
    }

    func type(_ text: String, window: NSWindow? = nil) async {
        log("TYPE \(text.count) characters")
        for character in text {
            await key(String(character), window: window)
        }
    }

    /// Types `text` quickly (long strings such as magnet links), with shift for capitals and symbols.
    func typeFast(_ text: String, window: NSWindow? = nil, delay: Double = 0.02) async {
        log("TYPE(fast) \(text.count) characters")
        for character in text {
            var base = character
            var shift = false
            if character.isUppercase {
                base = Character(character.lowercased())
                shift = true
            } else if let unshifted = Self.shiftedKeys[character] {
                base = unshifted
                shift = true
            }
            let code = Self.keyCodes[base] ?? Self.punctuationKeys[base]
            keyNow(String(character), code: code, modifiers: shift ? [.shift] : [], window: window, ignoring: String(base))
            await pause(delay)
        }
        await pause(0.2)
    }

    func pressReturn(window: NSWindow? = nil) async {
        log("KEY Return")
        await key("\r", code: 36, window: window)
    }

    func pressEscape(window: NSWindow? = nil) async {
        log("KEY Escape")
        await key("\u{1b}", code: 53, window: window)
    }

    func arrowDown() async {
        await key(String(UnicodeScalar(NSDownArrowFunctionKey)!), code: 125)
    }

    func command(_ character: String, shift: Bool = false) async {
        log("KEY Cmd-\(character)")
        // Posted to the event queue, so the application's own event loop dispatches it to the menus (a key
        // equivalent that quits would otherwise run its nested loop inside this task and starve the main actor).
        let modifiers: NSEvent.ModifierFlags = shift ? [.command, .shift] : [.command]
        let number = (NSApp.keyWindow ?? NSApp.mainWindow ?? windows.first)?.windowNumber ?? 0
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            guard let event = NSEvent.keyEvent(
                with: type, location: .zero, modifierFlags: modifiers, timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: number, context: nil, characters: character, charactersIgnoringModifiers: character,
                isARepeat: false, keyCode: Self.keyCodes[Character(character.lowercased())] ?? 0
            ) else { continue }
            NSApp.postEvent(event, atStart: false)
        }
        await pause(0.3)
    }
}
#endif
