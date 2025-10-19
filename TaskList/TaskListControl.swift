//
//  TaskListControl.swift
//  TaskList
//
//  Created by Xiao Xiao on 2025/10/20.
//

import AppIntents
import SwiftUI
import WidgetKit
import SwiftData
import Foundation

struct TaskListControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.xiao99xiao.Duey.TaskListControl",
            provider: Provider()
        ) { taskCount in
            ControlWidgetButton(action: OpenDueyAppIntent()) {
                HStack(spacing: 4) {
                    Image(systemName: "checklist")
                        .font(.system(.caption, weight: .medium))
                    Text("\(taskCount)")
                        .font(.system(.caption, weight: .semibold))
                }
                .foregroundStyle(.blue)
            }
        }
        .displayName("Task Count")
        .description("Shows pending task count and opens Duey app.")
    }
}

extension TaskListControl {
    struct Provider: ControlValueProvider {
        var previewValue: Int {
            3
        }

        func currentValue() async throws -> Int {
            // Return the number of unfinished tasks
            do {
                let schema = Schema([Task.self])
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic,
                    groupContainer: .identifier("group.com.xiao99xiao.Duey")
                )
                let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = ModelContext(modelContainer)

                let descriptor = FetchDescriptor<Task>(
                    predicate: #Predicate { !$0.isCompleted }
                )

                let tasks = try context.fetch(descriptor)
                print("Control Widget: Found \(tasks.count) unfinished tasks")
                return tasks.count
            } catch {
                print("Control Widget: Failed to fetch task count: \(error)")
                return 0
            }
        }
    }
}

struct OpenDueyAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Duey"
    static let description = IntentDescription("Opens the Duey app")

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

