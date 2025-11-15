//
//  TaskList.swift
//  TaskList
//
//  Created by Xiao Xiao on 2025/10/20.
//

import WidgetKit
import SwiftUI
import SwiftData
import Foundation

struct TaskProvider: TimelineProvider {
    typealias Entry = TaskEntry

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(
            date: Date(),
            tasks: [
                TaskInfo(title: "Review project proposal", daysUntilDeadline: 2),
                TaskInfo(title: "Team meeting preparation", daysUntilDeadline: 0),
                TaskInfo(title: "Submit quarterly report", daysUntilDeadline: 7),
                TaskInfo(title: "Schedule dentist appointment", daysUntilDeadline: nil),
                TaskInfo(title: "Update website content", daysUntilDeadline: 5)
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> ()) {
        let entry = TaskEntry(
            date: Date(),
            tasks: [
                TaskInfo(title: "Call dentist for appointment", daysUntilDeadline: 1),
                TaskInfo(title: "Buy groceries for dinner", daysUntilDeadline: 0),
                TaskInfo(title: "Prepare presentation slides", daysUntilDeadline: 3),
                TaskInfo(title: "Review code changes", daysUntilDeadline: nil)
            ]
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> ()) {
        _Concurrency.Task {
            let tasks = await fetchUnfinishedTasks()
            let entry = TaskEntry(date: Date(), tasks: tasks)

            // Update every 15 minutes to keep data fresh
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }

    private func fetchUnfinishedTasks() async -> [TaskInfo] {
        do {
            // Use CloudKit configuration to access same data as main app
            let schema = Schema([TaskSchemaV2.self])
            var modelContainer: ModelContainer?

            // First attempt: with CloudKit (same as main app)
            do {
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("Widget: Successfully created CloudKit ModelContainer")
            } catch {
                print("Widget: CloudKit failed (\(error)), trying local configuration")
                // Fallback: local configuration
                let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                modelContainer = try ModelContainer(for: schema, configurations: [fallbackConfiguration])
                print("Widget: Successfully created local ModelContainer")
            }

            guard let container = modelContainer else {
                throw NSError(domain: "Widget", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create ModelContainer"])
            }

            let context = ModelContext(container)

            let descriptor = FetchDescriptor<TaskSchemaV2>(
                predicate: #Predicate<TaskSchemaV2> { !$0.isCompleted }
            )

            let tasks = try context.fetch(descriptor)
            print("Widget: Found \(tasks.count) unfinished tasks")

            // Sort tasks the same way as the sidebar
            let sortedTasks = tasks.sorted { (task1, task2) in
                if let deadline1 = task1.deadline, let deadline2 = task2.deadline {
                    // Both have deadlines: earlier deadline first
                    return deadline1 < deadline2
                } else if task1.deadline != nil {
                    // Only task1 has deadline: it comes first
                    return true
                } else if task2.deadline != nil {
                    // Only task2 has deadline: it comes first
                    return false
                } else {
                    // Neither has deadline: newer tasks first
                    return task1.createdAt > task2.createdAt
                }
            }

            // Convert to TaskInfo
            return sortedTasks.map { task in
                TaskInfo(
                    title: task.title.isEmpty ? "Untitled Task" : task.title,
                    daysUntilDeadline: task.daysUntilDeadline
                )
            }
        } catch {
            print("Widget: Failed to fetch tasks: \(error)")
            return []
        }
    }
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskInfo]
}

struct TaskInfo {
    let title: String
    let daysUntilDeadline: Int?
}

struct TaskListEntryView: View {
    var entry: TaskProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(.title2))
                            .foregroundStyle(.green)
                        Text("All done!")
                            .font(.system(.body, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                // Task list only
                VStack(spacing: 4) {
                    ForEach(Array(displayedTasks.enumerated()), id: \.offset) { index, task in
                        TaskWidgetRow(task: task)
                    }
                }
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var displayedTasks: [TaskInfo] {
        let maxTasks: Int
        switch family {
        case .systemSmall:
            maxTasks = 3
        case .systemMedium:
            maxTasks = 6
        case .systemLarge:
            maxTasks = 12
        case .systemExtraLarge:
            maxTasks = 20
        default:
            maxTasks = 6
        }
        return Array(entry.tasks.prefix(maxTasks))
    }
}

struct TaskWidgetRow: View {
    let task: TaskInfo

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.secondary.opacity(0.4))
                .frame(width: 6, height: 6)

            Text(task.title)
                .font(.system(.body, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let days = task.daysUntilDeadline {
                DeadlineBadge(days: days)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct DeadlineBadge: View {
    let days: Int

    var body: some View {
        Text(badgeText)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var badgeText: String {
        switch days {
        case ..<0:
            return "\(abs(days))d"
        case 0:
            return "Today"
        case 1:
            return "1d"
        default:
            return "\(days)d"
        }
    }

    private var backgroundColor: Color {
        switch days {
        case ..<0:
            return .red.opacity(0.2)
        case 0:
            return .orange.opacity(0.2)
        case 1...3:
            return .yellow.opacity(0.2)
        default:
            return .secondary.opacity(0.15)
        }
    }

    private var textColor: Color {
        switch days {
        case ..<0:
            return .red
        case 0:
            return .orange
        case 1...3:
            return .yellow.opacity(0.8)
        default:
            return .secondary
        }
    }
}

struct TaskList: Widget {
    let kind: String = "TaskList"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            if #available(macOS 14.0, *) {
                TaskListEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                TaskListEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Task List")
        .description("Shows your unfinished tasks with deadlines.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}
