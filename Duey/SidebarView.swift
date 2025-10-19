//
//  SidebarView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    let tasks: [Task]
    @Binding var selectedTask: Task?
    @Binding var pendingNewTask: Task?
    let modelContext: ModelContext
    let onTaskDeleted: (Task) -> Void

    var body: some View {
        List(selection: $selectedTask) {
            ForEach(tasks, id: \.id) { task in
                TaskRowView(task: task)
                    .tag(task)
            }
            .onDelete(perform: deleteTask)
        }
        .deleteDisabled(false)
        .onDeleteCommand {
            if let selectedTask = selectedTask,
               let index = tasks.firstIndex(where: { $0.id == selectedTask.id }) {
                deleteTask(at: IndexSet(integer: index))
            }
        }
        .navigationTitle("Tasks")
        .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: createNewTask) {
                    Label("New Task", systemImage: "plus")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .createNewTask)) { _ in
            createNewTask()
        }
    }

    private func createNewTask() {
        let newTask = Task(title: "")
        modelContext.insert(newTask)
        pendingNewTask = newTask
        selectedTask = newTask
    }

    private func deleteTask(at offsets: IndexSet) {
        withAnimation {
            var newSelectedTask: Task? = nil

            for index in offsets {
                let task = tasks[index]

                // Call the callback before deletion
                onTaskDeleted(task)

                if task.id == pendingNewTask?.id {
                    pendingNewTask = nil
                }
                if task.id == selectedTask?.id {
                    // Find next task to select
                    if index < tasks.count - 1 {
                        // Select task below (next in list)
                        newSelectedTask = tasks[index + 1]
                    } else if index > 0 {
                        // If deleting last task, select task above
                        newSelectedTask = tasks[index - 1]
                    }
                    // If only one task, newSelectedTask stays nil
                }
                modelContext.delete(task)
            }

            selectedTask = newSelectedTask

            do {
                try modelContext.save()
            } catch {
                print("Failed to save after delete: \(error)")
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task

    var body: some View {
        HStack(spacing: 8) {
            Text(task.title.isEmpty ? "Untitled Task" : task.title)
                .font(.system(.body, design: .default, weight: .medium))
                .lineLimit(1)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                .strikethrough(task.isCompleted)
                .frame(maxWidth: .infinity, alignment: .leading)

            if task.isCompleted {
                CompletedBadge()
            } else if let days = task.daysUntilDeadline {
                DeadlineBadge(days: days)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

struct DeadlineBadge: View {
    let days: Int

    var body: some View {
        Text(badgeText)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 0.5)
            )
    }

    private var badgeText: String {
        switch days {
        case ..<0:
            return "\(abs(days))d late"
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
            return .red.opacity(0.1)
        case 0:
            return .orange.opacity(0.1)
        case 1...3:
            return .yellow.opacity(0.1)
        default:
            return .secondary.opacity(0.1)
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

    private var strokeColor: Color {
        switch days {
        case ..<0:
            return .red.opacity(0.3)
        case 0:
            return .orange.opacity(0.3)
        case 1...3:
            return .yellow.opacity(0.3)
        default:
            return .secondary.opacity(0.2)
        }
    }
}

struct CompletedBadge: View {
    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(.caption, weight: .medium))
            .foregroundStyle(.green)
            .background(Circle().fill(.green.opacity(0.1)).scaleEffect(1.5))
    }
}