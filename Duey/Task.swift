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
    var contentData: Data?
    var deadline: Date?
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?

    // Old property for backward compatibility - kept for migration from markdown to RTF
    var content: String?

    init(
        title: String = "",
        contentData: Data? = nil,
        deadline: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.title = title
        self.contentData = contentData
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.completedAt = nil
    }

    init(
        title: String,
        contentData: Data?,
        deadline: Date?,
        isCompleted: Bool,
        createdAt: Date,
        completedAt: Date?
    ) {
        self.title = title
        self.contentData = contentData
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }

    // Convenience initializer for creating tasks from plain text/markdown
    convenience init(
        title: String = "",
        content: String? = nil,
        deadline: Date? = nil,
        isCompleted: Bool = false
    ) {
        self.init(
            title: title,
            contentData: nil,
            deadline: deadline,
            isCompleted: isCompleted
        )

        // Convert plain text to AttributedString if provided
        if let contentString = content, !contentString.isEmpty {
            self.attributedContent = AttributedString(contentString)
        }
    }

    // Computed property to work with AttributedString
    var attributedContent: AttributedString {
        get {
            // First try to load from new RTF data
            if let data = contentData {
                do {
                    let nsAttributedString = try NSAttributedString(
                        data: data,
                        options: [.documentType: NSAttributedString.DocumentType.rtf],
                        documentAttributes: nil
                    )
                    return AttributedString(nsAttributedString)
                } catch {
                    print("Error loading RTF data: \(error)")
                }
            }

            // Fall back to old markdown content field if it exists
            if let oldContent = content, !oldContent.isEmpty {
                return AttributedString(oldContent)
            }

            // Return empty if both are nil
            return AttributedString("")
        }
        set {
            // Convert AttributedString to RTF Data
            let nsAttributedString = NSAttributedString(newValue)

            guard nsAttributedString.length > 0 else {
                contentData = nil
                return
            }

            do {
                let data = try nsAttributedString.data(
                    from: NSRange(location: 0, length: nsAttributedString.length),
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
                contentData = data
            } catch {
                print("Error saving RTF data: \(error)")
                contentData = nil
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