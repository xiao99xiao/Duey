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
        let mutableResult = NSMutableString()
        let fullRange = NSRange(location: 0, length: attributedString.length)

        var currentPosition = 0

        // Enumerate attachments
        attributedString.enumerateAttribute(
            .attachment,
            in: fullRange
        ) { value, range, stop in
            // Add any text before this attachment
            if range.location > currentPosition {
                let textRange = NSRange(location: currentPosition, length: range.location - currentPosition)
                mutableResult.append(attributedString.attributedSubstring(from: textRange).string)
            }

            // Convert checkbox attachment to markdown
            if let checkbox = value as? CheckboxAttachment {
                let markdownCheckbox = checkbox.isChecked ? "- [x]" : "- [ ]"
                mutableResult.append(markdownCheckbox)

                // Add checkbox text if it exists
                if !checkbox.text.isEmpty {
                    mutableResult.append(" ")
                    mutableResult.append(checkbox.text)
                }
            }

            currentPosition = range.location + range.length
        }

        // Add any remaining text after the last attachment
        if currentPosition < attributedString.length {
            let textRange = NSRange(location: currentPosition, length: attributedString.length - currentPosition)
            mutableResult.append(attributedString.attributedSubstring(from: textRange).string)
        }

        return mutableResult as String
    }

    // MARK: - Import (Markdown → Checkbox)

    /// Converts markdown text with checkbox syntax to NSAttributedString with CheckboxAttachment
    /// - Parameters:
    ///   - markdown: Source markdown text
    ///   - attributes: Default text attributes to apply
    /// - Returns: Attributed string with CheckboxAttachment instances
    static func fromMarkdown(_ markdown: String, attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Pattern to match markdown checkboxes: - [ ] or - [x]
        // Captures the checkbox state and optional text after it
        let pattern = "^- \\[([ x])\\]\\s*(.*)$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines])

        let nsString = markdown as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        var currentPosition = 0

        // Find all checkbox patterns
        regex?.enumerateMatches(in: markdown, options: [], range: fullRange) { match, flags, stop in
            guard let match = match else { return }

            // Add any text before this match
            if match.range.location > currentPosition {
                let textRange = NSRange(location: currentPosition, length: match.range.location - currentPosition)
                let text = nsString.substring(with: textRange)
                result.append(NSAttributedString(string: text, attributes: attributes))
            }

            // Extract checkbox state and text
            let stateRange = match.range(at: 1)
            let textRange = match.range(at: 2)

            let state = nsString.substring(with: stateRange)
            let checkboxText = nsString.substring(with: textRange)

            let isChecked = (state == "x")

            // Create checkbox attachment
            let checkbox = CheckboxAttachment(isChecked: isChecked, text: checkboxText)
            let attachmentString = NSMutableAttributedString(attachment: checkbox)

            // Add a space after checkbox if there's text
            if !checkboxText.isEmpty {
                attachmentString.append(NSAttributedString(string: " ", attributes: attributes))
            }

            result.append(attachmentString)

            currentPosition = match.range.location + match.range.length
        }

        // Add any remaining text
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
