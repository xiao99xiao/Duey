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

    // DEPRECATED: Keep for CloudKit schema compatibility only
    // CloudKit schema still has this field and will crash if we remove it completely
    // This field is never used in the app - all content is stored in contentData as RTF
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
        self.content = nil  // Explicitly initialize deprecated field
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
        self.content = nil  // Explicitly initialize deprecated field
    }

    // Computed property to work with AttributedString
    var attributedContent: AttributedString {
        get {
            // Try to load from RTF data
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

            // Fallback: Check old content field for backward compatibility
            if let oldContent = content, !oldContent.isEmpty {
                return AttributedString(oldContent)
            }

            // Return empty if no data
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