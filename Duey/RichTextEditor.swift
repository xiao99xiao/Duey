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
    @State private var showLinkPopover = false
    @State private var linkURL = ""
    @State private var linkText = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            // Text Editor
            TextEditor(text: $text, selection: $selection)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .background(
                    // Add list continuation support
                    ListContinuationHandler(text: $text)
                )
                .background(
                    // Add markdown copy support
                    MarkdownCopyHandler()
                )
                .safeAreaInset(edge: .bottom) {
                    // Reserve space for floating toolbar when visible
                    if hasSelection {
                        Color.clear.frame(height: 70)
                    }
                }

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
        .onAppear {
            // Set up keyboard shortcut for link insertion
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Check for Command+K
                if event.keyCode == 40 && event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.option) {
                    if hasSelection {
                        prepareLink()
                        showLinkPopover = true
                        return nil // Event handled
                    }
                }
                return event
            }
        }
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

            Divider()
                .frame(height: 16)

            // Link
            Button(action: {
                prepareLink()
                showLinkPopover = true
            }) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: hasLink ? .bold : .regular))
                    .foregroundStyle(hasLink ? .blue : .primary)
            }
            .buttonStyle(.plain)
            .help("Insert Link (⌘K)")
            .popover(isPresented: $showLinkPopover) {
                linkPopoverContent
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var linkPopoverContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insert Link")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Text:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Link text", text: $linkText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("URL:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("https://example.com", text: $linkURL)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
            }

            HStack {
                Button("Cancel") {
                    showLinkPopover = false
                    linkURL = ""
                    linkText = ""
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Insert") {
                    insertLink()
                }
                .keyboardShortcut(.return)
                .disabled(linkURL.isEmpty)
            }
        }
        .padding()
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

    private var hasLink: Bool {
        let attributes = selection.typingAttributes(in: text)
        return attributes.link != nil
    }

    // MARK: - Formatting Actions

    private func prepareLink() {
        // Pre-fill link text with selected text
        if case .ranges(let ranges) = selection.indices(in: text), !ranges.isEmpty {
            for range in ranges.ranges {
                linkText = String(text[range].characters)
                // Check if selection already has a link
                if let existingLink = text[range].runs.first?.link {
                    linkURL = existingLink.absoluteString
                }
                break
            }
        }
    }

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

    private func insertLink() {
        guard let url = URL(string: linkURL) else { return }

        let indices = selection.indices(in: text)

        switch indices {
        case .insertionPoint(let point):
            // Insert new link with provided text
            let displayText = linkText.isEmpty ? linkURL : linkText
            var linkString = AttributedString(displayText)
            let typingAttrs = selection.typingAttributes(in: text)
            linkString.setAttributes(typingAttrs)
            linkString.link = url
            text.insert(linkString, at: point)

        case .ranges(let rangeSet):
            // Apply link to selected text
            for range in rangeSet.ranges {
                text[range].link = url
                // If link text was provided, replace the selected text
                if !linkText.isEmpty {
                    var linkString = AttributedString(linkText)
                    let existingAttrs = text[range].runs.first?.attributes ?? AttributeContainer()
                    linkString.setAttributes(existingAttrs)
                    linkString.link = url
                    text.replaceSubrange(range, with: linkString)
                }
                break // Only apply to first range
            }
        }

        // Reset state
        showLinkPopover = false
        linkURL = ""
        linkText = ""
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
        // Always try to re-find the textView to handle view recreation
        DispatchQueue.main.async {
            // Check if current textView is still valid (has a window)
            if context.coordinator.textView?.window == nil {
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
                        print("📝 List continuation: Found and connected to NSTextView")
                        return
                    }
                }
                currentView = v.superview
            }
            print("⚠️ List continuation: Could not find NSTextView")
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

            print("📝 List continuation: Setting up key event monitor")

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

                // Check for Space key (auto-convert -, *, or 1. to list)
                if event.keyCode == 49 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                    print("📝 List continuation: Space key pressed")
                    if self.handleSpaceKey(textView) {
                        print("📝 List continuation: Space key handled (converted to list)")
                        return nil // Event handled, don't propagate
                    }
                    print("📝 List continuation: Space key not handled (no conversion)")
                }

                // Check for Tab key (indent list)
                if event.keyCode == 48 {
                    if event.modifierFlags.contains(.shift) {
                        // Shift+Tab - outdent
                        if self.handleOutdent(textView) {
                            return nil
                        }
                    } else if event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                        // Tab - indent
                        if self.handleIndent(textView) {
                            return nil
                        }
                    }
                }

                return event // Let event propagate normally
            }
        }

        private func handleIndent(_ textView: NSTextView) -> Bool {
            guard let textStorage = textView.textStorage else { return false }

            let cursorPosition = textView.selectedRange().location
            let string = textStorage.string as NSString

            // Find the current line
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            string.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: cursorPosition, length: 0))

            let lineRange = NSRange(location: lineStart, length: contentsEnd - lineStart)
            let lineText = string.substring(with: lineRange)

            // Check if line is a list item (starts with bullet or number)
            let isBulletList = lineText.hasPrefix("• ") || lineText.range(of: "^\\s+• ", options: .regularExpression) != nil
            let isNumberedList = lineText.range(of: "^\\s*\\d+\\. ", options: .regularExpression) != nil

            if isBulletList || isNumberedList {
                // Insert two spaces at the start of the line for indentation
                let attributes = textStorage.attributes(at: lineStart, effectiveRange: nil)
                let indent = NSAttributedString(string: "  ", attributes: attributes)

                textStorage.beginEditing()
                textStorage.insert(indent, at: lineStart)
                textStorage.endEditing()

                // Move cursor accordingly
                textView.setSelectedRange(NSRange(location: cursorPosition + 2, length: 0))

                return true
            }

            return false
        }

        private func handleOutdent(_ textView: NSTextView) -> Bool {
            guard let textStorage = textView.textStorage else { return false }

            let cursorPosition = textView.selectedRange().location
            let string = textStorage.string as NSString

            // Find the current line
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            string.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: cursorPosition, length: 0))

            let lineRange = NSRange(location: lineStart, length: contentsEnd - lineStart)
            let lineText = string.substring(with: lineRange)

            // Check if line starts with spaces
            if lineText.hasPrefix("  ") {
                // Remove two spaces from the start
                textStorage.beginEditing()
                textStorage.replaceCharacters(in: NSRange(location: lineStart, length: 2), with: "")
                textStorage.endEditing()

                // Move cursor back
                let newPosition = max(lineStart, cursorPosition - 2)
                textView.setSelectedRange(NSRange(location: newPosition, length: 0))

                return true
            }

            return false
        }

        private func handleSpaceKey(_ textView: NSTextView) -> Bool {
            guard let textStorage = textView.textStorage else {
                print("📝 List continuation: No textStorage")
                return false
            }

            let cursorPosition = textView.selectedRange().location
            print("📝 List continuation: Cursor position = \(cursorPosition)")

            // Need at least one character before cursor
            guard cursorPosition > 0 else {
                print("📝 List continuation: Cursor at start of document")
                return false
            }

            let string = textStorage.string as NSString

            // Find the start of the current line
            var lineStart = 0
            var lineEnd = 0
            var contentsEnd = 0
            string.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: cursorPosition, length: 0))

            // Get the text from line start to cursor
            let textBeforeCursor = string.substring(with: NSRange(location: lineStart, length: cursorPosition - lineStart))
            print("📝 List continuation: Text before cursor = '\(textBeforeCursor)'")

            // Check for numbered list pattern (e.g., "1.", "2.", etc.)
            let numberPattern = "^(\\d+)\\.$"
            if let regex = try? NSRegularExpression(pattern: numberPattern),
               regex.firstMatch(in: textBeforeCursor, range: NSRange(location: 0, length: textBeforeCursor.utf16.count)) != nil {
                print("📝 List continuation: Matched numbered list pattern")
                // It's already formatted as "1." - just insert a space after it
                let attributes = textStorage.attributes(at: cursorPosition - 1, effectiveRange: nil)

                textStorage.beginEditing()
                textStorage.insert(NSAttributedString(string: " ", attributes: attributes), at: cursorPosition)
                textStorage.endEditing()

                // Move cursor after the space
                textView.setSelectedRange(NSRange(location: cursorPosition + 1, length: 0))

                return true
            }

            // Check if cursor is right after the first character of the line
            print("📝 List continuation: lineStart = \(lineStart), cursorPosition = \(cursorPosition)")
            guard cursorPosition == lineStart + 1 else {
                print("📝 List continuation: Not at first character of line")
                return false
            }

            // Get the character before cursor
            let charBeforeCursor = string.character(at: cursorPosition - 1)
            let char = Character(UnicodeScalar(charBeforeCursor)!)
            print("📝 List continuation: Character before cursor = '\(char)'")

            // Check if it's - or *
            if char == "-" || char == "*" {
                print("📝 List continuation: Converting '\(char)' to bullet")

                // Replace the character with bullet and space
                textStorage.beginEditing()
                textStorage.replaceCharacters(in: NSRange(location: cursorPosition - 1, length: 1), with: "• ")
                textStorage.endEditing()

                // Move cursor after the bullet and space
                textView.setSelectedRange(NSRange(location: cursorPosition + 1, length: 0))

                return true
            }

            print("📝 List continuation: Character is not - or *")
            return false
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

            // Check if cursor is right after a bullet point marker (with or without indentation)
            let bulletPattern = "^(\\s*)• "
            if let regex = try? NSRegularExpression(pattern: bulletPattern),
               let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.utf16.count)) {
                let markerLength = match.range.length
                if cursorPosition == lineStart + markerLength {
                    // Remove the bullet marker (but keep indentation)
                    let indentLength = match.range(at: 1).length
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: lineStart + indentLength, length: 2), with: "")
                    textStorage.endEditing()
                    textView.setSelectedRange(NSRange(location: lineStart + indentLength, length: 0))
                    return true
                }
            }

            // Check if cursor is right after a numbered list marker (with or without indentation)
            let numberPattern = "^(\\s*)(\\d+)\\. "
            if let regex = try? NSRegularExpression(pattern: numberPattern),
               let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.utf16.count)) {
                let markerLength = match.range.length
                if cursorPosition == lineStart + markerLength {
                    // Remove the numbered marker (but keep indentation)
                    let indentLength = match.range(at: 1).length
                    let numberAndDotLength = match.range(at: 2).length + 2 // number + ". "
                    textStorage.beginEditing()
                    textStorage.replaceCharacters(in: NSRange(location: lineStart + indentLength, length: numberAndDotLength), with: "")
                    textStorage.endEditing()
                    textView.setSelectedRange(NSRange(location: lineStart + indentLength, length: 0))
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

            // Extract leading spaces (indentation)
            var indent = ""
            for char in lineText {
                if char == " " {
                    indent += " "
                } else {
                    break
                }
            }

            // Check if line has bullet point (with or without indentation)
            let bulletPattern = "^\\s*• "
            if lineText.range(of: bulletPattern, options: .regularExpression) != nil {
                // If line is just indentation + "• ", remove it and insert normal newline
                if lineText.trimmingCharacters(in: .whitespaces) == "•" {
                    textStorage.replaceCharacters(in: lineRange, with: "")
                    return false // Let default newline behavior happen
                }

                // Insert newline, indentation, and bullet
                let attributes = textStorage.attributes(at: cursorPosition > 0 ? cursorPosition - 1 : 0, effectiveRange: nil)
                let bullet = NSAttributedString(string: "\n\(indent)• ", attributes: attributes)

                textStorage.insert(bullet, at: cursorPosition)
                textView.setSelectedRange(NSRange(location: cursorPosition + bullet.length, length: 0))

                return true // We handled it
            }

            // Check if line has numbered list (with or without indentation)
            let numberPattern = "^\\s*(\\d+)\\. "
            if let regex = try? NSRegularExpression(pattern: numberPattern),
               let match = regex.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.utf16.count)) {

                // If line is just indentation + number, remove it and insert normal newline
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
                    let numberedItem = NSAttributedString(string: "\n\(indent)\(nextNumber). ", attributes: attributes)

                    textStorage.insert(numberedItem, at: cursorPosition)
                    textView.setSelectedRange(NSRange(location: cursorPosition + numberedItem.length, length: 0))

                    return true
                }
            }

            return false // Not a list, use default behavior
        }
    }
}

// MARK: - Markdown Copy Handler

struct MarkdownCopyHandler: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.isHidden = true

        DispatchQueue.main.async {
            context.coordinator.findAndSetupTextView(from: view)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Always try to re-find the textView to handle view recreation
        DispatchQueue.main.async {
            // Check if current textView is still valid (has a window)
            if context.coordinator.textView?.window == nil {
                context.coordinator.findAndSetupTextView(from: nsView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject {
        weak var textView: NSTextView?
        private var eventMonitor: Any?

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
                        setupCopyMonitor()
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

        private func setupCopyMonitor() {
            // Remove existing monitor if any
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
            }

            // Monitor Command+C
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self,
                      let textView = self.textView,
                      textView.window?.firstResponder == textView else {
                    return event
                }

                // Check for Command+C
                if event.keyCode == 8 && event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.option) {
                    self.handleCopy(textView)
                    return nil // Event handled
                }

                return event
            }
        }

        private func handleCopy(_ textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }

            let selectedRange = textView.selectedRange()
            guard selectedRange.length > 0 else { return }

            // Get the selected attributed text
            let selectedAttributedText = textStorage.attributedSubstring(from: selectedRange)

            // Convert to markdown
            let markdown = convertToMarkdown(selectedAttributedText)

            // Put both on pasteboard
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()

            // Add rich text (RTF)
            if let rtfData = selectedAttributedText.rtf(from: NSRange(location: 0, length: selectedAttributedText.length)) {
                pasteboard.setData(rtfData, forType: .rtf)
            }

            // Add plain text as markdown
            pasteboard.setString(markdown, forType: .string)
        }

        private func convertToMarkdown(_ attributedString: NSAttributedString) -> String {
            var markdown = ""
            let string = attributedString.string

            // Track current formatting state
            var currentBold = false
            var currentItalic = false
            var currentUnderline = false
            var currentStrikethrough = false
            var currentLink: URL? = nil

            attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length)) { attributes, range, _ in
                let substring = (string as NSString).substring(with: range)

                // Determine formatting for this range
                var isBold = false
                var isItalic = false
                var hasUnderline = false
                var hasStrikethrough = false
                var linkURL: URL? = nil

                if let font = attributes[.font] as? NSFont {
                    isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                    isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
                }

                if attributes[.underlineStyle] != nil {
                    hasUnderline = true
                }

                if attributes[.strikethroughStyle] != nil {
                    hasStrikethrough = true
                }

                if let link = attributes[.link] as? URL {
                    linkURL = link
                }

                // Handle link start
                if linkURL != nil && currentLink == nil {
                    markdown += "["
                }

                // Close link if it ended
                if currentLink != nil && linkURL == nil {
                    if let url = currentLink {
                        markdown += "](\(url.absoluteString))"
                    }
                }

                // Process each character to handle newlines specially
                for char in substring {
                    let isNewline = char == "\n"

                    // Close formatting before newline
                    if isNewline {
                        if currentStrikethrough {
                            markdown += "~~"
                        }
                        if currentUnderline {
                            markdown += "</u>"
                        }
                        if currentBold && currentItalic {
                            markdown += "***"
                        } else if currentBold {
                            markdown += "**"
                        } else if currentItalic {
                            markdown += "*"
                        }
                    } else {
                        // Open formatting if needed (not a newline and formatting changed)
                        if hasStrikethrough && !currentStrikethrough {
                            markdown += "~~"
                        }
                        if hasUnderline && !currentUnderline {
                            markdown += "<u>"
                        }
                        if isBold && isItalic && !(currentBold && currentItalic) {
                            markdown += "***"
                        } else if isBold && !currentBold {
                            markdown += "**"
                        } else if isItalic && !currentItalic {
                            markdown += "*"
                        }

                        // Close formatting if changed
                        if !hasStrikethrough && currentStrikethrough {
                            markdown += "~~"
                        }
                        if !hasUnderline && currentUnderline {
                            markdown += "</u>"
                        }
                        if !(isBold && isItalic) && currentBold && currentItalic {
                            markdown += "***"
                        } else if !isBold && currentBold && !currentItalic {
                            markdown += "**"
                        } else if !isItalic && currentItalic && !currentBold {
                            markdown += "*"
                        }
                    }

                    // Add the character
                    markdown.append(char)

                    // Reopen formatting after newline
                    if isNewline {
                        if hasStrikethrough {
                            markdown += "~~"
                        }
                        if hasUnderline {
                            markdown += "<u>"
                        }
                        if isBold && isItalic {
                            markdown += "***"
                        } else if isBold {
                            markdown += "**"
                        } else if isItalic {
                            markdown += "*"
                        }
                    }

                    // Update current state
                    currentBold = isBold
                    currentItalic = isItalic
                    currentUnderline = hasUnderline
                    currentStrikethrough = hasStrikethrough
                    currentLink = linkURL
                }
            }

            // Close any remaining formatting at the end
            if let url = currentLink {
                markdown += "](\(url.absoluteString))"
            }
            if currentStrikethrough {
                markdown += "~~"
            }
            if currentUnderline {
                markdown += "</u>"
            }
            if currentBold && currentItalic {
                markdown += "***"
            } else if currentBold {
                markdown += "**"
            } else if currentItalic {
                markdown += "*"
            }

            return markdown
        }
    }
}
