//
//  CheckboxAttachment.swift
//  Duey
//
//  Custom NSTextAttachment for interactive checkboxes
//

internal import AppKit
import Foundation

/// Custom text attachment that represents an interactive checkbox
class CheckboxAttachment: NSTextAttachment {
    // NSTextAttachment already conforms to NSSecureCoding
    override class var supportsSecureCoding: Bool { return true }

    // MARK: - Properties

    /// Unique identifier for this checkbox
    var id: UUID

    /// Whether the checkbox is checked
    var isChecked: Bool {
        didSet {
            if oldValue != isChecked {
                updateAttachmentData()
                NotificationCenter.default.post(name: .checkboxStateDidChange, object: self)
            }
        }
    }

    /// Text content associated with the checkbox
    var text: String {
        didSet {
            if oldValue != text {
                updateAttachmentData()
            }
        }
    }

    // MARK: - Initialization

    init(id: UUID = UUID(), isChecked: Bool = false, text: String = "") {
        self.id = id
        self.isChecked = isChecked
        self.text = text

        super.init(data: nil, ofType: nil)

        // Set up the attachment data
        updateAttachmentData()
    }

    required override init(data contentData: Data?, ofType uti: String?) {
        self.id = UUID()
        self.isChecked = false
        self.text = ""

        super.init(data: contentData, ofType: uti)

        // Try to restore from contentData if it's our JSON format
        if let contentData = contentData,
           let restored = CheckboxAttachment.from(data: contentData) {
            self.id = restored.id
            self.isChecked = restored.isChecked
            self.text = restored.text
        }

        updateAttachmentData()
    }

    required init?(coder: NSCoder) {
        // Initialize with defaults first
        self.id = UUID()
        self.isChecked = false
        self.text = ""

        super.init(coder: coder)

        // CRITICAL: Explicitly decode our contents data
        // NSTextAttachment's superclass does NOT automatically encode/decode contents!
        if let contentsData = coder.decodeObject(forKey: "checkboxContents") as? Data,
           let restored = CheckboxAttachment.from(data: contentsData) {
            self.id = restored.id
            self.isChecked = restored.isChecked
            self.text = restored.text
            self.contents = contentsData  // Also set contents field
        } else {
            updateAttachmentData()  // Generate default contents
        }
    }

    override func encode(with coder: NSCoder) {
        // CRITICAL: Update contents to reflect current state
        updateAttachmentData()

        super.encode(with: coder)

        // CRITICAL: Explicitly encode our contents data
        // NSTextAttachment's superclass does NOT automatically encode/decode contents!
        if let contents = self.contents {
            coder.encode(contents, forKey: "checkboxContents")
        }
    }

    // MARK: - Data Management

    /// Updates the attachment's data to store current state
    private func updateAttachmentData() {
        let checkboxData: [String: Any] = [
            "id": id.uuidString,
            "checked": isChecked,
            "text": text
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: checkboxData) {
            self.contents = jsonData
        }
    }

    /// Creates a checkbox attachment from JSON data
    static func from(data: Data) -> CheckboxAttachment? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let idString = json["id"] as? String,
              let id = UUID(uuidString: idString),
              let checked = json["checked"] as? Bool else {
            return nil
        }

        let text = json["text"] as? String ?? ""
        return CheckboxAttachment(id: id, isChecked: checked, text: text)
    }

    /// Restores CheckboxAttachments from an NSAttributedString that may contain generic NSTextAttachments
    /// This is needed because RTF round-trip loses the CheckboxAttachment subclass
    static func restoreCheckboxes(in attributedString: NSMutableAttributedString) {
        let range = NSRange(location: 0, length: attributedString.length)

        // Find all generic NSTextAttachments that have our checkbox JSON data
        attributedString.enumerateAttribute(.attachment, in: range) { value, attachmentRange, _ in
            guard let attachment = value as? NSTextAttachment,
                  !(attachment is CheckboxAttachment),
                  let contents = attachment.contents,
                  let checkboxAttachment = CheckboxAttachment.from(data: contents) else {
                return
            }

            // Replace generic attachment with CheckboxAttachment
            attributedString.addAttribute(.attachment, value: checkboxAttachment, range: attachmentRange)
        }
    }

    // MARK: - View Provider

    override func viewProvider(for parentView: NSView?, location: NSTextLocation, textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        return CheckboxViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let checkboxStateDidChange = Notification.Name("checkboxStateDidChange")
}
