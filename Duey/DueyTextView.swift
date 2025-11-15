//
//  DueyTextView.swift
//  Duey
//
//  Custom NSTextView with built-in auto-list conversion and markdown copy
//

internal import AppKit

/// Custom NSTextView that handles auto-list conversion, list continuation, and markdown export
class DueyTextView: NSTextView {

    // MARK: - Key Event Handling

    override func keyDown(with event: NSEvent) {
        // Handle Space key - auto-convert -, *, or 1. to list
        if event.keyCode == 49 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            if handleSpaceKey() {
                return // Event handled, don't call super
            }
        }

        // Handle Return key - continue lists on new line
        if event.keyCode == 36 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            if handleReturnKey() {
                return
            }
        }

        // Handle Delete/Backspace key - remove bullet markers
        if event.keyCode == 51 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
            if handleDeleteKey() {
                return
            }
        }

        // Handle Tab key - indent/outdent lists
        if event.keyCode == 48 {
            if event.modifierFlags.contains(.shift) {
                // Shift+Tab - outdent
                if handleOutdent() {
                    return
                }
            } else if event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                // Tab - indent
                if handleIndent() {
                    return
                }
            }
        }

        // Let NSTextView handle the event normally
        super.keyDown(with: event)
    }

    // MARK: - Auto-List Conversion

    /// Handles Space key - converts `- ` or `* ` to bullet, or adds space after `1.`
    private func handleSpaceKey() -> Bool {
        guard let textStorage = textStorage else { return false }

        let cursorPosition = selectedRange().location

        // Need at least one character before cursor
        guard cursorPosition > 0 else { return false }

        let string = textStorage.string as NSString

        // Find the start of the current line
        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0
        string.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: cursorPosition, length: 0))

        // Get the text from line start to cursor
        let textBeforeCursor = string.substring(with: NSRange(location: lineStart, length: cursorPosition - lineStart))

        // Check for numbered list pattern (e.g., "1.", "2.", etc.)
        let numberPattern = "^(\\d+)\\.$"
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           regex.firstMatch(in: textBeforeCursor, range: NSRange(location: 0, length: textBeforeCursor.utf16.count)) != nil {
            // It's already formatted as "1." - just insert a space after it
            let attributes = textStorage.attributes(at: cursorPosition - 1, effectiveRange: nil)

            textStorage.beginEditing()
            textStorage.insert(NSAttributedString(string: " ", attributes: attributes), at: cursorPosition)
            textStorage.endEditing()

            // Move cursor after the space
            setSelectedRange(NSRange(location: cursorPosition + 1, length: 0))

            return true
        }

        // Check if cursor is right after the first character of the line
        guard cursorPosition == lineStart + 1 else { return false }

        // Get the character before cursor
        let charBeforeCursor = string.character(at: cursorPosition - 1)
        let char = Character(UnicodeScalar(charBeforeCursor)!)

        // Check if it's - or *
        if char == "-" || char == "*" {
            // Replace the character with bullet and space
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: NSRange(location: cursorPosition - 1, length: 1), with: "• ")
            textStorage.endEditing()

            // Move cursor after the bullet and space
            setSelectedRange(NSRange(location: cursorPosition + 1, length: 0))

            return true
        }

        return false
    }

    // MARK: - List Continuation

    /// Handles Return key - continues lists on new line or removes empty bullets
    private func handleReturnKey() -> Bool {
        guard let textStorage = textStorage else { return false }

        let cursorPosition = selectedRange().location
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
            setSelectedRange(NSRange(location: cursorPosition + bullet.length, length: 0))

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
                setSelectedRange(NSRange(location: cursorPosition + numberedItem.length, length: 0))

                return true
            }
        }

        return false // Not a list, use default behavior
    }

    // MARK: - Bullet Removal

    /// Handles Delete key - removes bullet markers when backspacing
    private func handleDeleteKey() -> Bool {
        guard let textStorage = textStorage else { return false }

        let selectedRange = selectedRange()

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
                setSelectedRange(NSRange(location: lineStart + indentLength, length: 0))
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
                setSelectedRange(NSRange(location: lineStart + indentLength, length: 0))
                return true
            }
        }

        // Use default delete behavior
        return false
    }

    // MARK: - List Indentation

    /// Handles Tab key - adds 2 spaces for indentation
    private func handleIndent() -> Bool {
        guard let textStorage = textStorage else { return false }

        let cursorPosition = selectedRange().location
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
            setSelectedRange(NSRange(location: cursorPosition + 2, length: 0))

            return true
        }

        return false
    }

    /// Handles Shift+Tab - removes 2 spaces for outdenting
    private func handleOutdent() -> Bool {
        guard let textStorage = textStorage else { return false }

        let cursorPosition = selectedRange().location
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
            setSelectedRange(NSRange(location: newPosition, length: 0))

            return true
        }

        return false
    }

    // MARK: - Checkbox Support

    /// Inserts a checkbox at the current cursor position or converts selected text to checkbox
    func insertCheckbox() {
        guard let textStorage = textStorage else { return }

        let selectedRange = selectedRange()
        let cursorPosition = selectedRange.location

        // Get the selected text (if any) to use as checkbox label
        let selectedText = selectedRange.length > 0 ?
            textStorage.attributedSubstring(from: selectedRange).string : ""

        // Create checkbox attachment
        let checkbox = CheckboxAttachment(isChecked: false, text: selectedText)

        // Create attributed string with the attachment
        let attachmentString = NSMutableAttributedString(attachment: checkbox)

        // If there's selected text, we need to add a space after checkbox
        if !selectedText.isEmpty {
            attachmentString.append(NSAttributedString(string: " "))
        }

        // Insert or replace
        textStorage.beginEditing()
        textStorage.replaceCharacters(in: selectedRange, with: attachmentString)
        textStorage.endEditing()

        // Move cursor after the checkbox
        let newPosition = cursorPosition + attachmentString.length
        setSelectedRange(NSRange(location: newPosition, length: 0))
    }

    // MARK: - Markdown Copy

    /// Override copy to export selected text as markdown
    override func copy(_ sender: Any?) {
        guard let textStorage = textStorage else {
            super.copy(sender)
            return
        }

        let selectedRange = selectedRange()
        guard selectedRange.length > 0 else {
            super.copy(sender)
            return
        }

        // Get the selected attributed text
        let selectedAttributedText = textStorage.attributedSubstring(from: selectedRange)

        // Put both on pasteboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // Add rich text (RTF)
        if let rtfData = selectedAttributedText.rtf(from: NSRange(location: 0, length: selectedAttributedText.length)) {
            pasteboard.setData(rtfData, forType: .rtf)
        }

        // Add plain text
        pasteboard.setString(selectedAttributedText.string, forType: .string)
    }
}
