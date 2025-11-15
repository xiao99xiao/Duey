//
//  CheckboxViewProvider.swift
//  Duey
//
//  View provider for checkbox attachments
//

import AppKit

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
        // Return the size of the checkbox view
        // Height matches line height, width is square
        let height = proposedLineFragment.height
        return CGRect(x: 0, y: 0, width: height, height: height)
    }
}
