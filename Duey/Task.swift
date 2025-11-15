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
    var content: String?  // Original text content field
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
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.completedAt = nil
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