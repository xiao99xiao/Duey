//
//  CheckboxAttachment.swift
//  Duey
//
//  Custom NSTextAttachment for interactive checkboxes
//

import AppKit
import Foundation

/// Custom text attachment that represents an interactive checkbox
class CheckboxAttachment: NSTextAttachment {

    // MARK: - Properties

    /// Unique identifier for this checkbox
    let id: UUID

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

    required init?(coder: NSCoder) {
        // Decode stored properties
        if let idString = coder.decodeObject(forKey: "id") as? String,
           let uuid = UUID(uuidString: idString) {
            self.id = uuid
        } else {
            self.id = UUID()
        }

        self.isChecked = coder.decodeBool(forKey: "isChecked")
        self.text = coder.decodeObject(forKey: "text") as? String ?? ""

        super.init(coder: coder)

        updateAttachmentData()
    }

    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(id.uuidString, forKey: "id")
        coder.encode(isChecked, forKey: "isChecked")
        coder.encode(text, forKey: "text")
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

    // MARK: - View Provider

    override func viewProvider(for parentView: NSView?, location: NSTextLocation, textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        return CheckboxViewProvider(textAttachment: self, parentView: parentView, textLayoutManager: textContainer?.textLayoutManager, location: location)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let checkboxStateDidChange = Notification.Name("checkboxStateDidChange")
}
