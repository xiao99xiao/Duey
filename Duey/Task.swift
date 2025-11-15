//
//  Task.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class DueyTask {
    var title: String = ""
    var contentRTF: Data?  // RTF formatted content
    var deadline: Date?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?

    init(
        title: String = "",
        deadline: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.title = title
        self.contentRTF = nil
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.completedAt = nil
    }

    // MARK: - Rich Content Helper

    /// Direct access to RTF content
    var richContent: Data? {
        get {
            return contentRTF
        }
        set {
            contentRTF = newValue
        }
    }

    // MARK: - Checkbox Statistics

    /// Returns checkbox statistics (checked count, total count)
    /// Returns nil if there are no checkboxes
    var checkboxStats: (checked: Int, total: Int)? {
        guard let rtfData = contentRTF else { return nil }

        // Convert RTF to NSAttributedString
        guard let attrString = try? NSAttributedString(
            data: rtfData,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return nil
        }

        var totalCount = 0
        var checkedCount = 0

        // Enumerate through the attributed string to find checkbox attachments
        attrString.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: attrString.length)
        ) { value, range, stop in
            if let attachment = value as? CheckboxAttachment {
                totalCount += 1
                if attachment.isChecked {
                    checkedCount += 1
                }
            }
        }

        // Return nil if no checkboxes found
        return totalCount > 0 ? (checked: checkedCount, total: totalCount) : nil
    }

    func markAsCompleted() {
        isCompleted = true
        completedAt = Date()
    }

    func markAsIncomplete() {
        isCompleted = false
        completedAt = nil
    }

    var daysUntilDeadline: Int? {
        guard let deadline = deadline else { return nil }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: deadline)
        return components.day
    }

    var formattedDeadline: String? {
        guard let deadline = deadline else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: deadline)
    }

    static func defaultDeadlineTime(for date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 18
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? date
    }

}