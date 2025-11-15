//
//  TaskSchemaV1.swift
//  Duey
//
//  Schema version 1 - Original Task model before adding contentData
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class TaskSchemaV1 {
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
}
