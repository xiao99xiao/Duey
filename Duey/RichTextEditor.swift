//
//  RichTextEditor.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/26.
//

import SwiftUI
internal import AppKit

struct RichTextEditor: View {
    @Binding var text: AttributedString
    @State private var selection = AttributedTextSelection()
    @Environment(\.fontResolutionContext) var fontResolutionContext

    var body: some View {
        VStack(spacing: 0) {
            // Text Editor
            TextEditor(text: $text, selection: $selection)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .background(
                    // Add list continuation support
                    ListContinuationHandler(text: $text)
                )

            // Formatting Toolbar (appears when text is selected)
            if hasSelection {
                formattingToolbar
                    .padding(8)
                    .background(.regularMaterial)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.bottom, 12)
                    .transition(
                        .asymmetric(
                            insertion: .offset(y: 10).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                            removal: .offset(y: 8).combined(with: .opacity).combined(with: .scale(scale: 0.98))
                        )
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasSelection)
    }

    // MARK: - Selection State

    private var hasSelection: Bool {
        guard case .ranges(let ranges) = selection.indices(in: text) else {
            return false
        }
        return !ranges.isEmpty
    }

    private var formattingToolbar: some View {
        HStack(spacing: 12) {
            // Bold
            Button(action: toggleBold) {
                Image(systemName: "bold")
                    .font(.system(size: 14, weight: isBold ? .bold : .regular))
                    .foregroundStyle(isBold ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Bold (⌘B)")

            Divider()
                .frame(height: 16)

            // Italic
            Button(action: toggleItalic) {
                Image(systemName: "italic")
                    .font(.system(size: 14, weight: isItalic ? .bold : .regular))
                    .foregroundStyle(isItalic ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Italic (⌘I)")

            Divider()
                .frame(height: 16)

            // Underline
            Button(action: toggleUnderline) {
                Image(systemName: "underline")
                    .font(.system(size: 14, weight: hasUnderline ? .bold : .regular))
                    .foregroundStyle(hasUnderline ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Underline (⌘U)")

            Divider()
                .frame(height: 16)

            // Strikethrough
            Button(action: toggleStrikethrough) {
                Image(systemName: "strikethrough")
                    .font(.system(size: 14, weight: hasStrikethrough ? .bold : .regular))
                    .foregroundStyle(hasStrikethrough ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Strikethrough")

            Divider()
                .frame(height: 16)

            // Bulleted List
            Button(action: insertBulletPoint) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Bullet List")

            // Numbered List
            Button(action: insertNumberedPoint) {
                Image(systemName: "list.number")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .help("Numbered List")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Formatting State

    private var isBold: Bool {
        let attributes = selection.typingAttributes(in: text)
        let currentFont = attributes.font ?? .default
        let resolved = currentFont.resolve(in: fontResolutionContext)
        return resolved.isBold
    }

    private var isItalic: Bool {
        let attributes = selection.typingAttributes(in: text)
        let currentFont = attributes.font ?? .default
        let resolved = currentFont.resolve(in: fontResolutionContext)
        return resolved.isItalic
    }

    private var hasUnderline: Bool {
        let attributes = selection.typingAttributes(in: text)
        return attributes.underlineStyle != nil
    }

    private var hasStrikethrough: Bool {
        let attributes = selection.typingAttributes(in: text)
        return attributes.strikethroughStyle != nil
    }

    // MARK: - Formatting Actions

    private func toggleBold() {
        text.transformAttributes(in: &selection) { container in
            let currentFont = container.font ?? .default
            let resolved = currentFont.resolve(in: fontResolutionContext)
            container.font = currentFont.bold(!resolved.isBold)
        }
    }

    private func toggleItalic() {
        text.transformAttributes(in: &selection) { container in
            let currentFont = container.font ?? .default
            let resolved = currentFont.resolve(in: fontResolutionContext)
            container.font = currentFont.italic(!resolved.isItalic)
        }
    }

    private func toggleUnderline() {
        text.transformAttributes(in: &selection) { container in
            if container.underlineStyle != nil {
                container.underlineStyle = nil
            } else {
                container.underlineStyle = .single
            }
        }
    }

    private func toggleStrikethrough() {
        text.transformAttributes(in: &selection) { container in
            if container.strikethroughStyle != nil {
                container.strikethroughStyle = nil
            } else {
                container.strikethroughStyle = .single
            }
        }
    }

    private func insertBulletPoint() {
        // Get the insertion point or first range
        let indices = selection.indices(in: text)

        switch indices {
        case .insertionPoint(let point):
            // Insert bullet at cursor position
            var bullet = AttributedString("• ")
            let typingAttrs = selection.typingAttributes(in: text)
            bullet.setAttributes(typingAttrs)
            text.insert(bullet, at: point)

        case .ranges(let rangeSet):
            // Insert bullet at the start of the first range
            for range in rangeSet.ranges {
                var bullet = AttributedString("• ")
                let typingAttrs = selection.typingAttributes(in: text)
                bullet.setAttributes(typingAttrs)
                text.insert(bullet, at: range.lowerBound)
                break // Only insert at the first range
            }
        }
    }

    private func insertNumberedPoint() {
        // Get the insertion point or first range
        let indices = selection.indices(in: text)

        switch indices {
        case .insertionPoint(let point):
            // Insert numbered point at cursor position
            var number = AttributedString("1. ")
            let typingAttrs = selection.typingAttributes(in: text)
            number.setAttributes(typingAttrs)
            text.insert(number, at: point)

        case .ranges(let rangeSet):
            // Insert numbered point at the start of the first range
            for range in rangeSet.ranges {
                var number = AttributedString("1. ")
                let typingAttrs = selection.typingAttributes(in: text)
                number.setAttributes(typingAttrs)
                text.insert(number, at: range.lowerBound)
                break // Only insert at the first range
            }
        }
    }
}

// MARK: - List Continuation Handler

struct ListContinuationHandler: NSViewRepresentable {
    @Binding var text: AttributedString

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.isHidden = true

        DispatchQueue.main.async {
            context.coordinator.findAndSetupTextView(from: view)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if context.coordinator.textView == nil {
            DispatchQueue.main.async {
                context.coordinator.findAndSetupTextView(from: nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject {
        @Binding var text: AttributedString
        weak var textView: NSTextView?
        private var eventMonitor: Any?

        init(text: Binding<AttributedString>) {
            self._text = text
            super.init()
        }

        deinit {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        func findAndSetupTextView(from view: NSView) {
            var currentView: NSView? = view
            while let v = currentView {
                if let window = v.window {
                    if let textView = findTextView(in: window.contentView) {
                        self.textView = textView
                        setupKeyEventMonitor()
                        print("✅ List continuation handler set up")
                        return
                    }
                }
                currentView = v.superview
            }
        }

        private func findTextView(in view: NSView?) -> NSTextView? {
            guard let view = view else { return nil }

            if let textView = view as? NSTextView {
                return textView
            }

            for subview in view.subviews {
                if let textView = findTextView(in: subview) {
                    return textView
                }
            }

            return nil
        }

        private func setupKeyEventMonitor() {
            // Remove existing monitor if any
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }

            // Monitor key events locally
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self,
                      let textView = self.textView,
                      textView.window?.firstResponder == textView else {
                    return event
                }

                // Check for Return key
                if event.keyCode == 36 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                    if self.handleReturnKey(textView) {
                        return nil // Event handled, don't propagate
                    }
                }

                // Check for Delete/Backspace key
                if event.keyCode == 51 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                    if self.handleDeleteKey(textView) {
                        return nil // Event handled, don't propagate
                    }
                }

                return event // Let event propagate normally
            }
        }

        private func handleDeleteKey(_ textView: NSTextView) -> Bool {
            guard let textStorage = textView.textStorage else { return false }

            let selectedRange = textView.selectedRange()

            // If there's a selection, let default behavior handle it
            if selectedRange.length > 0 {
                return false
            }

            let cursorPosition = selectedRange.location

            // If at start of document, nothing to delete
            if cursorPosition == 0 {
                return false
            }

            // Find the current line
            let string = textStorage.string as NSString
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            string.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: cursorPosition, length: 0))

            // Get the current line text
            let lineRange = NSRange(location: lineStart, length: contentsEnd - lineStart)
            let lineText = string.substring(with: lineRange)

            // Check if cursor is right after a bullet point marker at the start of line
            if cursorPosition == lineStart + 2 && lineText.hasPrefix("• ") {
                // Remove the bullet marker
                textStorage.beginEditing()
                textStorage.replaceCharacters(in: NSRange(location: lineStart, length: 2), with: "")
                textStorage.endEditing()
                textView.setSelectedRange(NSRange(location: lineStart, length: 0))
                return true
            }

            // Check if cursor is right after a numbered list marker
            let numberPattern = "^(\\d+)\\. "
            if let regex = try? NSRegularExpression(pattern: numberPattern),
               let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.utf16.count)) {
                let markerLength = match.range.length
                if cursorPosition == lineStart + markerLength {
                    // Remove the numbered marker
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: lineStart, length: markerLength), with: "")
                    textStorage.endEditing()
                    textView.setSelectedRange(NSRange(location: lineStart, length: 0))
                    return true
                }
            }

            // Use default delete behavior
            return false
        }

        private func handleReturnKey(_ textView: NSTextView) -> Bool {
            guard let textStorage = textView.textStorage else { return false }

            let cursorPosition = textView.selectedRange().location
            guard cursorPosition <= textStorage.length else { return false }

            // Find the start of the current line
            let string = textStorage.string as NSString
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            string.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: cursorPosition, length: 0))

            // Get the current line text
            let lineRange = NSRange(location: lineStart, length: contentsEnd - lineStart)
            let lineText = string.substring(with: lineRange)

            // Check if line starts with bullet point
            if lineText.hasPrefix("• ") {
                // If line is just "• ", remove it and insert normal newline
                if lineText.trimmingCharacters(in: .whitespaces) == "•" {
                    textStorage.replaceCharacters(in: lineRange, with: "")
                    return false // Let default newline behavior happen
                }

                // Insert newline and bullet
                let attributes = textStorage.attributes(at: cursorPosition > 0 ? cursorPosition - 1 : 0, effectiveRange: nil)
                let bullet = NSAttributedString(string: "\n• ", attributes: attributes)

                textStorage.insert(bullet, at: cursorPosition)
                textView.setSelectedRange(NSRange(location: cursorPosition + 3, length: 0))

                return true // We handled it
            }

            // Check if line starts with numbered list (e.g., "1. ", "2. ", etc.)
            let numberPattern = "^(\\d+)\\. "
            if let regex = try? NSRegularExpression(pattern: numberPattern),
               let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.utf16.count)) {

                // If line is just the number, remove it and insert normal newline
                if lineText.trimmingCharacters(in: .whitespaces).hasSuffix(".") {
                    textStorage.replaceCharacters(in: lineRange, with: "")
                    return false
                }

                // Extract the number and increment it
                let numberRange = match.range(at: 1)
                let numberString = (lineText as NSString).substring(with: numberRange)
                if let number = Int(numberString) {
                    let nextNumber = number + 1
                    let attributes = textStorage.attributes(at: cursorPosition > 0 ? cursorPosition - 1 : 0, effectiveRange: nil)
                    let numberedItem = NSAttributedString(string: "\n\(nextNumber). ", attributes: attributes)

                    textStorage.insert(numberedItem, at: cursorPosition)
                    textView.setSelectedRange(NSRange(location: cursorPosition + numberedItem.length, length: 0))

                    return true
                }
            }

            return false // Not a list, use default behavior
        }
    }
}
