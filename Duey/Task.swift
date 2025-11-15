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
final class Task {
    var title: String = ""
    var content: String?  // Deprecated - kept for CloudKit compatibility
    var contentRTF: Data?  // New RTF formatted content
    var deadline: Date?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?

    init(
        title: String = "",
        content: String? = nil,
        deadline: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.title = title
        self.content = content
        self.contentRTF = nil
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.completedAt = nil
    }

    // MARK: - Rich Content Helper

    /// Unified access to content - prefers RTF, falls back to plain text
    var richContent: Data? {
        get {
            // Prefer RTF if it exists
            if let rtf = contentRTF {
                return rtf
            }

            // Fallback: convert old plain text to RTF
            if let plainText = content, !plainText.isEmpty {
                let attrString = NSAttributedString(string: plainText)
                return try? attrString.data(
                    from: NSRange(location: 0, length: attrString.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
            }

            return nil
        }
        set {
            contentRTF = newValue
            // Keep content in sync for backwards compatibility (extract plain text)
            if let rtfData = newValue,
               let attrString = try? NSAttributedString(
                   data: rtfData,
                   options: [.documentType: NSAttributedString.DocumentType.rtf],
                   documentAttributes: nil
               ) {
                content = attrString.string
            } else {
                content = nil
            }
        }
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