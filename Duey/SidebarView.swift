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

    var body: some View {
        List(selection: $selectedTask) {
            ForEach(tasks) { task in
                TaskRowView(task: task)
                    .tag(task)
            }
            .onDelete(perform: deleteTask)
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
    }

    private func createNewTask() {
        let newTask = Task(title: "")
        modelContext.insert(newTask)
        pendingNewTask = newTask
        selectedTask = newTask
    }

    private func deleteTask(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let task = tasks[index]
                if task.id == pendingNewTask?.id {
                    pendingNewTask = nil
                }
                if task.id == selectedTask?.id {
                    selectedTask = nil
                }
                modelContext.delete(task)
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title.isEmpty ? "Untitled Task" : task.title)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)

                if let days = task.daysUntilDeadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(deadlineText(days: days))
                            .font(.caption)
                            .foregroundStyle(deadlineColor(days: days))
                    }
                }
            }

            Spacer()

            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }

    private func deadlineText(days: Int) -> String {
        switch days {
        case ..<0:
            return "\(abs(days)) days overdue"
        case 0:
            return "Due today"
        case 1:
            return "Due tomorrow"
        default:
            return "Due in \(days) days"
        }
    }

    private func deadlineColor(days: Int) -> Color {
        switch days {
        case ..<0:
            return .red
        case 0:
            return .orange
        case 1...3:
            return .yellow
        default:
            return .secondary
        }
    }
}