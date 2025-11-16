//
//  CheckboxMarkdownConverter.swift
//  Duey
//
//  Utility for converting checkboxes to/from markdown format
//

import Foundation
internal import AppKit

/// Converts between CheckboxAttachment and markdown checkbox syntax
class CheckboxMarkdownConverter {

    // MARK: - Export (Checkbox → Markdown)

    /// Converts NSAttributedString with CheckboxAttachment to markdown text
    /// - Parameter attributedString: Source attributed string with checkboxes
    /// - Returns: Plain text with markdown checkbox syntax (- [ ] or - [x])
    static func toMarkdown(_ attributedString: NSAttributedString) -> String {
        let result = NSMutableString()
        let string = attributedString.string as NSString

        // Iterate through each character
        for i in 0..<attributedString.length {
            // Check if this position has an attachment
            if let attachment = attributedString.attribute(.attachment, at: i, effectiveRange: nil) as? CheckboxAttachment {
                // Convert checkbox to markdown with a space after it
                let markdownCheckbox = attachment.isChecked ? "- [x] " : "- [ ] "
                result.append(markdownCheckbox)
            } else {
                // Regular character - just append it
                let char = string.character(at: i)
                result.append(String(utf16CodeUnits: [char], count: 1))
            }
        }

        return result as String
    }

    // MARK: - Import (Markdown → Checkbox)

    /// Converts markdown text with checkbox syntax to NSAttributedString with CheckboxAttachment
    /// - Parameters:
    ///   - markdown: Source markdown text
    ///   - attributes: Default text attributes to apply
    /// - Returns: Attributed string with CheckboxAttachment instances
    static func fromMarkdown(_ markdown: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Pattern to match markdown checkboxes at start of line: - [ ] or - [x]
        let pattern = "^- \\[([ x])\\]"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])

        let nsString = markdown as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        var currentPosition = 0

        // Find all checkbox patterns
        regex?.enumerateMatches(in: markdown, options: [], range: fullRange) { match, flags, stop in
            guard let match = match else { return }

            // Add any text before this match (preserving everything including newlines)
            if match.range.location > currentPosition {
                let textRange = NSRange(location: currentPosition, length: match.range.location - currentPosition)
                let text = nsString.substring(with: textRange)
                result.append(NSAttributedString(string: text, attributes: attributes))
            }

            // Extract checkbox state
            let stateRange = match.range(at: 1)
            let state = nsString.substring(with: stateRange)
            let isChecked = (state == "x")

            // Create checkbox attachment (no space needed, checkbox width provides spacing)
            let checkbox = CheckboxAttachment(isChecked: isChecked, text: "")
            let attachmentString = NSMutableAttributedString(attachment: checkbox)

            result.append(attachmentString)

            currentPosition = match.range.location + match.range.length
        }

        // Add any remaining text (preserving everything including newlines)
        if currentPosition < nsString.length {
            let textRange = NSRange(location: currentPosition, length: nsString.length - currentPosition)
            let text = nsString.substring(with: textRange)
            result.append(NSAttributedString(string: text, attributes: attributes))
        }

        // If no matches found, just return the original text
        if result.length == 0 {
            return NSAttributedString(string: markdown, attributes: attributes)
        }

        return result
    }
}
