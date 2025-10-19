//
//  ContentView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData
import KeyboardShortcuts

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var selectedTask: Task?
    @State private var pendingNewTask: Task?
    @State private var deletedTaskBackup: Task?
    @State private var showDeleteToast = false
    @StateObject private var appSettings = AppSettings()
    @StateObject private var smartTaskCapture = SmartTaskCapture()

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

        // Only include completed tasks if the setting is enabled
        var allTasks = unfinishedTasks

        if appSettings.showCompletedTasks {
            let finishedTasks = tasks.filter { $0.isCompleted }
                .sorted { (task1, task2) in
                    guard let completed1 = task1.completedAt,
                          let completed2 = task2.completedAt else {
                        return false
                    }
                    return completed1 > completed2
                }
            allTasks += finishedTasks
        }

        return allTasks
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                tasks: sortedTasks,
                selectedTask: $selectedTask,
                pendingNewTask: $pendingNewTask,
                modelContext: modelContext,
                onTaskDeleted: { deletedTask in
                    deletedTaskBackup = deletedTask
                    showDeleteToast = true
                }
            )
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: {
                        smartTaskCapture.analyzeClipboard()
                    }) {
                        Label("Analyze Clipboard", systemImage: "clipboard.fill")
                    }
                    .help("Test Smart Task Capture (\(KeyboardShortcuts.getShortcut(for: .smartTaskCapture)?.description ?? "⌘⇧T"))")
                    .disabled(!appSettings.smartCaptureEnabled || appSettings.smartCaptureAPIKey.isEmpty)
                }
            }
        } detail: {
            if let selectedTask = selectedTask {
                TaskDetailView(task: selectedTask, pendingNewTask: $pendingNewTask)
                    .id(selectedTask.id)
            } else {
                EmptyStateView(pendingNewTask: $pendingNewTask)
            }
        }
        .overlay(alignment: .bottom) {
            if showDeleteToast, let deletedTask = deletedTaskBackup {
                DeleteToastView(
                    taskTitle: deletedTask.title,
                    onRevert: { revertDeletion() },
                    onDismiss: {
                        showDeleteToast = false
                        deletedTaskBackup = nil
                    }
                )
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(
            // Only capture Command+Z when there's something to revert
            Group {
                if showDeleteToast && deletedTaskBackup != nil {
                    Button("") {
                        revertDeletion()
                    }
                    .keyboardShortcut("z", modifiers: .command)
                    .hidden()
                }
            }
        )
        .overlay {
            // Smart Task Capture suggestion dialog
            if smartTaskCapture.showSuggestionDialog,
               let suggestion = smartTaskCapture.currentSuggestion {
                TaskSuggestionOverlay(
                    isPresented: $smartTaskCapture.showSuggestionDialog,
                    suggestion: suggestion,
                    originalText: smartTaskCapture.currentOriginalText,
                    onAccept: { title, content, deadline in
                        smartTaskCapture.acceptSuggestion(title: title, content: content, deadline: deadline)
                        // Select the newly created task
                        if let newTask = tasks.first(where: { $0.title == title }) {
                            selectedTask = newTask
                        }
                    },
                    onDecline: {
                        smartTaskCapture.declineSuggestion()
                    }
                )
            }
        }
        .onAppear {
            smartTaskCapture.configure(modelContext: modelContext, appSettings: appSettings)

            // Configure contextual menu service
            TextAnalysisService.shared.configure(
                modelContainer: modelContext.container,
                appSettings: appSettings,
                smartTaskCapture: smartTaskCapture
            )

            // Set up global keyboard shortcut
            KeyboardShortcuts.onKeyUp(for: .smartTaskCapture) {
                smartTaskCapture.analyzeClipboard()
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

    private func revertDeletion() {
        guard let deletedTask = deletedTaskBackup else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            // Create a new task with the same properties
            let restoredTask = Task(
                title: deletedTask.title,
                content: deletedTask.content,
                deadline: deletedTask.deadline,
                isCompleted: deletedTask.isCompleted,
                createdAt: deletedTask.createdAt,
                completedAt: deletedTask.completedAt
            )

            modelContext.insert(restoredTask)
            selectedTask = restoredTask

            // Clear the backup and hide toast
            deletedTaskBackup = nil
            showDeleteToast = false

            do {
                try modelContext.save()
            } catch {
                print("Failed to save restored task: \(error)")
            }
        }
    }
}

struct EmptyStateView: View {
    @Binding var pendingNewTask: Task?
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)

            Text("No Task Selected")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("Select a task from the sidebar or create a new one")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct DeleteToastView: View {
    let taskTitle: String
    let onRevert: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("Deleted task: \"\(taskTitle.isEmpty ? "Untitled Task" : taskTitle)\"")
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Button("Revert", action: onRevert)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(maxWidth: 400)
        .onAppear {
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}