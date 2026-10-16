#if DEBUG
import AppKit

/// Drags and accessibility actions of the in-process UI driver.
extension UIDriver {
    /// Presses the mouse at the centre of `element`, drags it by `delta` (window points, y up) in a few steps
    /// and releases it, like a user dragging a divider.
    func drag(_ element: Element, by delta: NSPoint, steps: Int = 6) async {
        let window = element.window
        await ensureKey(window)
        var frame = self.frame(of: element.object)
        if frame.isEmpty { frame = element.frame }
        let start = point(in: window, frame: frame)
        log("DRAG \(element.role) '\(element.label)' from \(Int(start.x)),\(Int(start.y)) by \(Int(delta.x)),\(Int(delta.y))")
        guard let view = window.contentView?.superview?.hitTest(start) else { log("DRAG: nothing hit"); return }
        log("DRAG hit view \(Swift.type(of: view))")
        // The events go straight to the hit view, in order, as AppKit dispatches them during a real drag.
        let count = max(steps, 1)
        if let down = mouse(.leftMouseDown, at: start, in: window) { view.mouseDown(with: down) }
        await pause(0.05)
        for step in 1 ... count {
            let fraction = CGFloat(step) / CGFloat(count)
            let location = NSPoint(x: start.x + delta.x * fraction, y: start.y + delta.y * fraction)
            if let event = mouse(.leftMouseDragged, at: location, in: window) { view.mouseDragged(with: event) }
            await pause(0.05)
        }
        if let up = mouse(.leftMouseUp, at: NSPoint(x: start.x + delta.x, y: start.y + delta.y), in: window) { view.mouseUp(with: up) }
        await pause(0.4)
    }

    /// Performs an accessibility action selector (`accessibilityPerformIncrement`, …) on an element.
    @discardableResult
    func perform(_ selector: String, on object: NSObject) -> Bool {
        let sel = NSSelectorFromString(selector)
        guard object.responds(to: sel) else { log("\(object.className) does not respond to \(selector)"); return false }
        _ = object.perform(sel)
        return true
    }
}
#endif
