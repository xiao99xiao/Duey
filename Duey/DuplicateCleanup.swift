//
//  DuplicateCleanup.swift
//  Duey
//
//  Utility to clean up duplicate tasks
//

import Foundation
import SwiftData

@MainActor
class DuplicateCleanup {

    /// Remove duplicate tasks based on title, deadline, and creation time
    static func removeDuplicates(modelContext: ModelContext) throws {
        print("Starting duplicate cleanup...")

        // Fetch all tasks
        let descriptor = FetchDescriptor<DueyTask>(sortBy: [SortDescriptor(\.createdAt)])
        let tasks = try modelContext.fetch(descriptor)

        print("Found \(tasks.count) total tasks")

        // Group tasks by key (title + deadline + createdAt within 1 second)
        var taskGroups: [String: [DueyTask]] = [:]

        for task in tasks {
            let key = makeTaskKey(task)
            if taskGroups[key] == nil {
                taskGroups[key] = []
            }
            taskGroups[key]?.append(task)
        }

        // For each group with duplicates, keep the first one and delete the rest
        var deletedCount = 0
        for (_, duplicates) in taskGroups {
            if duplicates.count > 1 {
                print("Found \(duplicates.count) duplicates of task: '\(duplicates[0].title)'")
                // Keep the first task, delete the rest
                for i in 1..<duplicates.count {
                    modelContext.delete(duplicates[i])
                    deletedCount += 1
                }
            }
        }

        if deletedCount > 0 {
            try modelContext.save()
            print("Deleted \(deletedCount) duplicate tasks")
        } else {
            print("No duplicates found")
        }
    }

    /// Create a unique key for task comparison
    private static func makeTaskKey(_ task: DueyTask) -> String {
        let titleKey = task.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let deadlineKey = task.deadline?.timeIntervalSince1970.description ?? "no-deadline"
        // Round creation time to nearest second to catch near-duplicates
        let createdKey = Int(task.createdAt.timeIntervalSince1970)
        let completedKey = task.isCompleted.description

        return "\(titleKey)-\(deadlineKey)-\(createdKey)-\(completedKey)"
    }
}
