//
//  TaskSuggestionDialog.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI

struct TaskSuggestionDialog: View {
    let suggestion: TaskExtractionResponse
    let originalText: String
    @Binding var isPresented: Bool

    let onAccept: (String, String?, Date?) -> Void
    let onDecline: () -> Void

    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var editedDeadline: Date?
    @State private var renderMarkdown: Bool = true

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()


    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)

                Text("Add Task from Clipboard?")
                    .font(.headline)

                Spacer()

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                    onDecline()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel")
            }

            // Task Title
            TextField("Task title", text: $editedTitle)
                .textFieldStyle(.roundedBorder)
                .font(.body)

            // Task Description
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: { renderMarkdown.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: renderMarkdown ? "doc.richtext" : "doc.plaintext")
                            Text(renderMarkdown ? "Rich" : "Plain")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }

                if renderMarkdown && !editedContent.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if let attributedContent = try? AttributedString(markdown: editedContent, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                Text(attributedContent)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(editedContent)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(8)
                    }
                    .frame(height: 80)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                } else {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                        .frame(height: 80)
                }
            }

            // Deadline display (read-only)
            if let deadline = editedDeadline {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(.orange)
                    Text("Deadline: \(dateFormatter.string(from: deadline))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                    onDecline()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Add Task") {
                    let content = editedContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalContent = content.isEmpty ? nil : content

                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                    onAccept(editedTitle, finalContent, editedDeadline)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            setupInitialValues()
        }
    }

    private func setupInitialValues() {
        editedTitle = suggestion.title ?? ""
        editedContent = suggestion.content ?? ""

        if let deadlineString = suggestion.deadline {
            let formatter = ISO8601DateFormatter()
            editedDeadline = formatter.date(from: deadlineString)
        }

        // Auto-enable markdown rendering if content contains markdown syntax
        renderMarkdown = editedContent.contains("#") || editedContent.contains("*") || editedContent.contains("-")
    }
}

struct TaskSuggestionWindow: View {
    let suggestion: TaskExtractionResponse
    let originalText: String
    let smartTaskCapture: SmartTaskCapture

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        TaskSuggestionDialog(
            suggestion: suggestion,
            originalText: originalText,
            isPresented: .constant(true),
            onAccept: { title, content, deadline in
                smartTaskCapture.acceptSuggestion(title: title, content: content, deadline: deadline)
                dismissWindow(id: "task-suggestion")
            },
            onDecline: {
                smartTaskCapture.declineSuggestion()
                dismissWindow(id: "task-suggestion")
            }
        )
        .frame(width: 400)
        .background(Color.clear)
        .onAppear {
            // Bring app to front when task suggestion window appears
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

#Preview {
    TaskSuggestionDialog(
        suggestion: TaskExtractionResponse(
            isTask: true,
            confidence: 0.85,
            title: "Call dentist for appointment",
            deadline: "2025-10-20T14:00:00Z",
            content: "Schedule a cleaning appointment at the dentist office."
        ),
        originalText: "Remember to call the dentist tomorrow at 2pm to schedule cleaning appointment",
        isPresented: .constant(true),
        onAccept: { _, _, _ in },
        onDecline: { }
    )
}
