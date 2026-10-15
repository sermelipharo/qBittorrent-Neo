import AppKit
import SwiftUI

/// The palette's search field: a plain, large text field that keeps focus and
/// turns the list keys into palette navigation (↑/↓ move, Return runs, Tab or
/// → at the end opens a row's nested list, Shift-Tab, ← at the start or ⌫ in
/// an empty field go back, Escape goes back or closes).
/// AppKit because SwiftUI's `TextField` consumes ↑/↓ and Tab before `onKeyPress`.
struct PaletteSearchField: NSViewRepresentable {
    let model: CommandPaletteModel

    func makeNSView(context: Context) -> FocusingTextField {
        let field = FocusingTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .preferredFont(forTextStyle: .title3)
        field.cell?.isScrollable = true
        field.cell?.wraps = false
        field.lineBreakMode = .byTruncatingTail
        field.delegate = context.coordinator
        field.setAccessibilityLabel(String(localized: "palette.title", defaultValue: "Command Palette",
                                           comment: "Command Palette window and menu item"))
        return field
    }

    func updateNSView(_ field: FocusingTextField, context: Context) {
        context.coordinator.model = model
        if field.stringValue != model.query { field.stringValue = model.query }
        if field.placeholderString != model.placeholder { field.placeholderString = model.placeholder }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    /// Takes focus as soon as it is in a window.
    final class FocusingTextField: NSTextField {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate {
        var model: CommandPaletteModel

        init(model: CommandPaletteModel) {
            self.model = model
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            model.query = field.stringValue
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
            let text = textView.string as NSString
            let caret = textView.selectedRange()
            switch selector {
            case #selector(NSResponder.moveUp(_:)):
                model.moveSelection(by: -1)
            case #selector(NSResponder.moveDown(_:)):
                model.moveSelection(by: 1)
            case #selector(NSResponder.scrollPageUp(_:)), #selector(NSResponder.pageUp(_:)):
                model.moveSelection(by: -8)
            case #selector(NSResponder.scrollPageDown(_:)), #selector(NSResponder.pageDown(_:)):
                model.moveSelection(by: 8)
            case #selector(NSResponder.moveToBeginningOfDocument(_:)), #selector(NSResponder.scrollToBeginningOfDocument(_:)):
                model.selectFirst()
            case #selector(NSResponder.moveToEndOfDocument(_:)), #selector(NSResponder.scrollToEndOfDocument(_:)):
                model.selectLast()
            case #selector(NSResponder.insertNewline(_:)):
                model.runSelected()
            case #selector(NSResponder.cancelOperation(_:)):
                model.cancel()
            case #selector(NSResponder.insertTab(_:)):
                model.drillIn()
            case #selector(NSResponder.insertBacktab(_:)):
                model.back()
            case #selector(NSResponder.moveRight(_:)):
                // → at the end of the text opens the nested list; elsewhere it moves the caret.
                guard caret.length == 0, caret.location == text.length else { return false }
                return model.drillIn()
            case #selector(NSResponder.moveLeft(_:)):
                guard caret.length == 0, caret.location == 0, model.isNested else { return false }
                return model.back()
            case #selector(NSResponder.deleteBackward(_:)):
                guard text.length == 0, model.isNested else { return false }
                return model.back()
            default:
                return false
            }
            return true
        }
    }
}
