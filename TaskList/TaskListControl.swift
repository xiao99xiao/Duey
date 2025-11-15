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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
extension TaskListControl {
    struct Provider: ControlValueProvider {
        var previewValue: Int {
            3
        }

        func currentValue() async throws -> Int {
            // Return the number of unfinished tasks using CloudKit
            do {
                let schema = Schema([DueyTask.self])
                var modelContainer: ModelContainer?

                // First attempt: with CloudKit (same as main app)
                do {
                    let modelConfiguration = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: false,
                        cloudKitDatabase: .automatic
                    )
                    modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    print("Control Widget: Successfully created CloudKit ModelContainer")
                } catch {
                    print("Control Widget: CloudKit failed (\(error)), trying local configuration")
                    // Fallback: local configuration
                    let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                    modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                    print("Control Widget: Successfully created local ModelContainer")
                }

                guard let container = modelContainer else {
                    throw NSError(domain: "ControlWidget", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create ModelContainer"])
                }

                let context = ModelContext(container)

                let descriptor = FetchDescriptor<DueyTask>(
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

