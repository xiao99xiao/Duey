//
//  ContentView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var selectedTask: Task?
    @State private var pendingNewTask: Task?

    var sortedTasks: [Task] {
        let unfinishedTasks = tasks.filter { !$0.isCompleted }
            .sorted { (task1, task2) in
                if let deadline1 = task1.deadline, let deadline2 = task2.deadline {
                    return deadline1 < deadline2
                } else if task1.deadline != nil {
                    return true
                } else if task2.deadline != nil {
                    return false
                } else {
                    return task1.createdAt > task2.createdAt
                }
            }

        let finishedTasks = tasks.filter { $0.isCompleted }
            .sorted { (task1, task2) in
                guard let completed1 = task1.completedAt,
                      let completed2 = task2.completedAt else {
                    return false
                }
                return completed1 > completed2
            }

        return unfinishedTasks + finishedTasks
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                tasks: sortedTasks,
                selectedTask: $selectedTask,
                pendingNewTask: $pendingNewTask,
                modelContext: modelContext
            )
        } detail: {
            if let selectedTask = selectedTask {
                TaskDetailView(task: selectedTask, pendingNewTask: $pendingNewTask)
                    .id(selectedTask.id)
            } else {
                EmptyStateView(pendingNewTask: $pendingNewTask)
            }
        }
        .onChange(of: selectedTask) { oldTask, newTask in
            handleTaskSelectionChange(from: oldTask, to: newTask)
        }
    }

    private func handleTaskSelectionChange(from oldTask: Task?, to newTask: Task?) {
        if let pendingTask = pendingNewTask,
           oldTask?.id == pendingTask.id,
           pendingTask.title.isEmpty {
            modelContext.delete(pendingTask)
            pendingNewTask = nil
        }
    }
}

struct EmptyStateView: View {
    @Binding var pendingNewTask: Task?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Text("No Task Selected")
                .font(.title2)
                .foregroundStyle(.secondary)

            Button("Create New Task") {
                createNewTask()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func createNewTask() {
        let newTask = Task(title: "")
        modelContext.insert(newTask)
        pendingNewTask = newTask
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}