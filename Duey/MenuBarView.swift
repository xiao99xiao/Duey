//
//  MenuBarView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/20.
//

import SwiftUI
import SwiftData

struct MenuBarView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.openWindow) private var openWindow
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Task> { !$0.isCompleted }) private var unfinishedTasks: [Task]

    var body: some View {
        // Show Duey
        Button(action: openMainWindow) {
            Label("Open Duey", systemImage: "checkmark.square")
        }
        .keyboardShortcut("o", modifiers: .command)

        Divider()

        // New Task
        Button(action: createNewTask) {
            Label("New Task", systemImage: "plus.circle")
        }

        Divider()

        // Quick task overview
        if !unfinishedTasks.isEmpty {
            Section("Pending Tasks") {
                ForEach(unfinishedTasks.prefix(5), id: \.id) { task in
                    Button(action: {
                        openMainWindow()
                        // Select this task after opening
                        NotificationCenter.default.post(
                            name: .selectTask,
                            object: nil,
                            userInfo: ["taskId": task.id]
                        )
                    }) {
                        HStack {
                            Text(task.title.isEmpty ? "Untitled Task" : task.title)
                                .lineLimit(1)

                            Spacer()

                            if let days = task.daysUntilDeadline {
                                Text(deadlineText(days: days))
                                    .font(.caption)
                                    .foregroundStyle(deadlineColor(days: days))
                            }
                        }
                    }
                }

                if unfinishedTasks.count > 5 {
                    Text("\(unfinishedTasks.count - 5) more...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
        }

        // Preferences
        SettingsLink {
            Text("Preferences...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        // Quit
        Button("Quit Duey") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func openMainWindow() {
        // Open or focus the main window
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)

        // Ensure the window is brought to front
        DispatchQueue.main.async {
            if let mainWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                mainWindow.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func createNewTask() {
        openMainWindow()
        // Trigger new task creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NotificationCenter.default.post(name: .createNewTask, object: nil)
        }
    }

    private func deadlineText(days: Int) -> String {
        switch days {
        case ..<0:
            return "\(abs(days))d late"
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        default:
            return "\(days)d"
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

extension Notification.Name {
    static let createNewTask = Notification.Name("createNewTask")
    static let selectTask = Notification.Name("selectTask")
}

#Preview {
    MenuBarView()
        .frame(width: 250)
}