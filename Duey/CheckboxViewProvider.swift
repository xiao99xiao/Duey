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

    // MARK: - Initialization

    override init(textAttachment: NSTextAttachment, parentView: NSView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)

        // Control view sizing through tracksTextAttachmentViewBounds
        self.tracksTextAttachmentViewBounds = true
    }

    // MARK: - View Creation

    override func loadView() {
        super.loadView()

        guard let attachment = textAttachment as? CheckboxAttachment else {
            return
        }

        let checkbox = CheckboxView(attachment: attachment)

        // Set explicit frame size to ensure proper layout
        checkbox.frame = NSRect(x: 0, y: 0, width: 20, height: 16)

        checkboxView = checkbox
        view = checkbox
    }

    // MARK: - Sizing

    override func attachmentBounds(for attributes: [NSAttributedString.Key : Any], location: NSTextLocation, textContainer: NSTextContainer?, proposedLineFragment: CGRect, position: CGPoint) -> CGRect {
        // Use a fixed size for the checkbox (width=20 for extra spacing, height=16)
        let checkboxWidth: CGFloat = 20.0
        let checkboxHeight: CGFloat = 16.0

        // Calculate Y-offset to align with text baseline
        // Get font from attributes to calculate proper alignment
        let font = attributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)

        // Align checkbox vertically centered with the font's cap height
        // This puts it inline with uppercase letters
        let yOffset = (font.descender + font.capHeight - checkboxHeight) / 2.0

        return CGRect(x: 0, y: yOffset, width: checkboxWidth, height: checkboxHeight)
    }
}
