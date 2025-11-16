//
//  CheckboxViewProvider.swift
//  Duey
//
//  View provider for checkbox attachments
//

internal import AppKit

/// Provides views for checkbox attachments
class CheckboxViewProvider: NSTextAttachmentViewProvider {

    // MARK: - Properties

    private var checkboxView: CheckboxView?

    // MARK: - View Creation

    override func loadView() {
        super.loadView()

        guard let attachment = textAttachment as? CheckboxAttachment else {
            return
        }

        let checkbox = CheckboxView(attachment: attachment)
        checkboxView = checkbox
        view = checkbox
    }

    // MARK: - Sizing

    override func attachmentBounds(for attributes: [NSAttributedString.Key : Any], location: NSTextLocation, textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        // Use a fixed, reasonable size for the checkbox
        let checkboxSize: CGFloat = 16.0

        // Calculate Y-offset to align with text baseline
        // Get font from attributes to calculate proper alignment
        let font = attributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)

        // Align checkbox vertically centered with the font's cap height
        // This puts it inline with uppercase letters
        let yOffset = (font.descender + font.capHeight - checkboxSize) / 2.0

        let bounds = CGRect(x: 0, y: yOffset, width: checkboxSize, height: checkboxSize)

        // DEBUG: Log the bounds and line fragment
        print("📏 CheckboxViewProvider.attachmentBounds:")
        print("   proposedLineFragment: \(proposedLineFragment)")
        print("   font: \(font.fontName) \(font.pointSize)pt")
        print("   font.descender: \(font.descender), capHeight: \(font.capHeight)")
        print("   calculated yOffset: \(yOffset)")
        print("   returning bounds: \(bounds)")

        return bounds
    }
}
