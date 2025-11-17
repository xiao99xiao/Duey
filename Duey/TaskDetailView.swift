//
//  TaskDetailView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData
import WidgetKit

struct TaskDetailView: View {
    @Bindable var task: DueyTask
    @Binding var pendingNewTask: DueyTask?
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @Environment(\.modelContext) private var modelContext
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TaskHeaderView(
                task: task,
                showingDatePicker: $showingDatePicker,
                showingTimePicker: $showingTimePicker,
                titleFocused: $titleFocused
            )

            Divider()

            RichTextEditorView(task: task)
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if task.isCompleted {
                    Button(action: {
                        withAnimation {
                            task.markAsIncomplete()
                        }
                    }) {
                        Label("Mark Incomplete", systemImage: "checkmark.circle.fill")
                    }
                    .foregroundStyle(.green)
                } else {
                    Button(action: {
                        withAnimation {
                            task.markAsCompleted()
                        }
                    }) {
                        Label("Mark Done", systemImage: "circle")
                    }
                }
            }
        }
        .onAppear {
            if task.id == pendingNewTask?.id && task.title.isEmpty {
                titleFocused = true
            }
        }
        .onChange(of: task.isCompleted) { _, _ in
            WidgetCenter.shared.reloadTimelines(ofKind: "TaskList")
        }
        .onChange(of: task.deadline) { _, _ in
            WidgetCenter.shared.reloadTimelines(ofKind: "TaskList")
        }
        .onChange(of: task.title) { _, _ in
            WidgetCenter.shared.reloadTimelines(ofKind: "TaskList")
        }
    }

}

struct TaskHeaderView: View {
    @Bindable var task: DueyTask
    @Binding var showingDatePicker: Bool
    @Binding var showingTimePicker: Bool
    @FocusState.Binding var titleFocused: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            TextField("Task Title", text: $task.title, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.title2)
                .lineLimit(1...3)
                .frame(maxWidth: .infinity)
                .focused($titleFocused)
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .trailing, spacing: 8) {
                // Checkbox statistics indicator
                if let stats = task.checkboxStats {
                    HStack(spacing: 6) {
                        // Circular progress indicator
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                                .frame(width: 16, height: 16)

                            Circle()
                                .trim(from: 0, to: stats.total > 0 ? CGFloat(stats.checked) / CGFloat(stats.total) : 0)
                                .stroke(stats.checked == stats.total ? Color.green : Color.blue, lineWidth: 2)
                                .frame(width: 16, height: 16)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.3), value: stats.checked)
                        }

                        Text("\(stats.checked)/\(stats.total)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Image(systemName: "checkmark.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }

                HStack(alignment: .center, spacing: 8) {
                    Button(action: { showingDatePicker.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(dateText)
                                .font(.caption)
                        }
                        .foregroundStyle(deadlineColor)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(height: 24)
                    .help("Set date")
                    .popover(isPresented: $showingDatePicker) {
                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: { task.deadline ?? Date() },
                                set: { newDate in
                                    if let existingDeadline = task.deadline {
                                        // Preserve time, update date
                                        let calendar = Calendar.current
                                        let timeComponents = calendar.dateComponents([.hour, .minute], from: existingDeadline)
                                        let dateComponents = calendar.dateComponents([.year, .month, .day], from: newDate)

                                        var combined = DateComponents()
                                        combined.year = dateComponents.year
                                        combined.month = dateComponents.month
                                        combined.day = dateComponents.day
                                        combined.hour = timeComponents.hour
                                        combined.minute = timeComponents.minute

                                        task.deadline = calendar.date(from: combined)
                                    } else {
                                        // Set new date with default time (18:00)
                                        task.deadline = DueyTask.defaultDeadlineTime(for: newDate)
                                    }
                                }
                            ),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .focusEffectDisabled()
                        .padding()
                    }

                    Button(action: { showingTimePicker.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(timeText)
                                .font(.caption)
                        }
                        .foregroundStyle(deadlineColor)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(height: 24)
                    .help("Set time")
                    .popover(isPresented: $showingTimePicker) {
                        DatePicker(
                            "Time",
                            selection: Binding(
                                get: { task.deadline ?? DueyTask.defaultDeadlineTime(for: Date()) },
                                set: { newTime in
                                    if let existingDeadline = task.deadline {
                                        // Preserve date, update time
                                        let calendar = Calendar.current
                                        let dateComponents = calendar.dateComponents([.year, .month, .day], from: existingDeadline)
                                        let timeComponents = calendar.dateComponents([.hour, .minute], from: newTime)

                                        var combined = DateComponents()
                                        combined.year = dateComponents.year
                                        combined.month = dateComponents.month
                                        combined.day = dateComponents.day
                                        combined.hour = timeComponents.hour
                                        combined.minute = timeComponents.minute

                                        task.deadline = calendar.date(from: combined)
                                    } else {
                                        // Set today's date with selected time
                                        let calendar = Calendar.current
                                        let todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
                                        let timeComponents = calendar.dateComponents([.hour, .minute], from: newTime)

                                        var combined = DateComponents()
                                        combined.year = todayComponents.year
                                        combined.month = todayComponents.month
                                        combined.day = todayComponents.day
                                        combined.hour = timeComponents.hour
                                        combined.minute = timeComponents.minute

                                        task.deadline = calendar.date(from: combined)
                                    }
                                }
                            ),
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .focusEffectDisabled()
                        .padding()
                    }

                    if task.deadline != nil {
                        Button(action: {
                            task.deadline = nil
                            showingDatePicker = false
                            showingTimePicker = false
                        }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .frame(height: 24)
                        .foregroundStyle(.secondary)
                        .help("Clear deadline")
                    }
                }
            }
        }
        .padding()
    }

    private var dateText: String {
        if let deadline = task.deadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: deadline)
        } else {
            return "Date"
        }
    }

    private var timeText: String {
        if let deadline = task.deadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter.string(from: deadline)
        } else {
            return "Time"
        }
    }

    private var deadlineColor: Color {
        guard let days = task.daysUntilDeadline else { return .blue }
        switch days {
        case ..<0: return .red
        case 0: return .orange
        case 1...3: return .yellow
        default: return .blue
        }
    }
}

