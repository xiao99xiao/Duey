//
//  TaskDetailView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Bindable var task: Task
    @Binding var pendingNewTask: Task?
    @State private var showingDatePicker = false
    @Environment(\.modelContext) private var modelContext
    @FocusState private var titleFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                TaskHeaderView(
                    task: task,
                    showingDatePicker: $showingDatePicker,
                    titleFocused: $titleFocused
                )

                Divider()

                MarkdownEditorView(task: task)
                    .padding(.bottom, 80)
            }

            FloatingActionView(task: task)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("New Task", systemImage: "plus") {
                    createNewTask()
                }
            }
        }
        .onAppear {
            if task.id == pendingNewTask?.id && task.title.isEmpty {
                titleFocused = true
            }
        }
        .popover(isPresented: $showingDatePicker) {
            DeadlinePickerView(deadline: $task.deadline)
                .frame(width: 320, height: 400)
        }
    }

    private func createNewTask() {
        let newTask = Task(title: "")
        modelContext.insert(newTask)
        pendingNewTask = newTask
    }
}

struct TaskHeaderView: View {
    @Bindable var task: Task
    @Binding var showingDatePicker: Bool
    @FocusState.Binding var titleFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            TextField("Task Title", text: $task.title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.title2)
                .focused($titleFocused)
                .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 4) {
                Button(action: { showingDatePicker.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text(deadlineButtonText)
                            .font(.caption)
                    }
                    .foregroundStyle(deadlineButtonColor)
                }
                .buttonStyle(.plain)
                .help("Set deadline")

                if task.deadline != nil {
                    Button("Clear", systemImage: "xmark.circle.fill") {
                        task.deadline = nil
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var deadlineButtonText: String {
        if let deadline = task.deadline {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: deadline, relativeTo: Date())
        } else {
            return "Set Deadline"
        }
    }

    private var deadlineButtonColor: Color {
        guard let days = task.daysUntilDeadline else { return .blue }
        switch days {
        case ..<0: return .red
        case 0: return .orange
        case 1...3: return .yellow
        default: return .blue
        }
    }
}

struct DeadlinePickerView: View {
    @Binding var deadline: Date?
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Set Deadline")
                .font(.headline)
                .padding(.top)

            DatePicker(
                "Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)

            DatePicker(
                "Time",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.compact)
            .frame(maxWidth: 200)

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Clear") {
                    deadline = nil
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Set") {
                    let calendar = Calendar.current
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

                    var combinedComponents = DateComponents()
                    combinedComponents.year = dateComponents.year
                    combinedComponents.month = dateComponents.month
                    combinedComponents.day = dateComponents.day
                    combinedComponents.hour = timeComponents.hour ?? 18
                    combinedComponents.minute = timeComponents.minute ?? 0

                    deadline = calendar.date(from: combinedComponents)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom)
        }
        .padding()
        .onAppear {
            if let deadline = deadline {
                selectedDate = deadline
                selectedTime = deadline
            } else {
                selectedTime = Task.defaultDeadlineTime(for: Date())
            }
        }
    }
}

struct FloatingActionView: View {
    @Bindable var task: Task

    var body: some View {
        VStack(spacing: 8) {
            if task.isCompleted {
                if let completedAt = task.completedAt {
                    Text("Completed \(completedAt.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button("Mark as Incomplete") {
                    withAnimation {
                        task.markAsIncomplete()
                    }
                }
                .buttonStyle(.bordered)
            } else {
                Button("Mark as Done") {
                    withAnimation {
                        task.markAsCompleted()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
        .padding()
    }
}

