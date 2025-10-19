//
//  MarkdownEditorView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData
import MarkdownUI
import HighlightedTextEditor

struct MarkdownEditorView: View {
    @Bindable var task: Task
    @State private var showPreview = true
    @State private var editorHeight: CGFloat = 400

    var body: some View {
        HSplitView {
            // Editor with syntax highlighting
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Markdown")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    MarkdownToolbar(text: Binding(
                        get: { task.content ?? "" },
                        set: { task.content = $0.isEmpty ? nil : $0 }
                    ))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                ScrollView {
                    HighlightedTextEditor(
                        text: Binding(
                            get: { task.content ?? "" },
                            set: { task.content = $0.isEmpty ? nil : $0 }
                        ),
                        highlightRules: .markdown
                    )
                    .font(.system(.body, design: .monospaced))
                    .introspect { editor in
                        // Customize the text view if needed
                        editor.textView?.isAutomaticQuoteSubstitutionEnabled = false
                        editor.textView?.isAutomaticSpellingCorrectionEnabled = false
                    }
                    .frame(minHeight: editorHeight)
                    .padding(12)
                }
                .background(Color(NSColor.textBackgroundColor))
            }

            // Preview with MarkdownUI
            if showPreview {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(action: { showPreview = false }) {
                            Image(systemName: "xmark")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))

                    Divider()

                    ScrollView {
                        Markdown(task.content ?? "")
                            .markdownTheme(.gitHub)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if !showPreview {
                Button(action: { showPreview = true }) {
                    Label("Show Preview", systemImage: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .padding(8)
            }
        }
        .onAppear {
            calculateEditorHeight()
        }
    }

    private func calculateEditorHeight() {
        let lineCount = (task.content ?? "").components(separatedBy: .newlines).count
        editorHeight = max(400, CGFloat(lineCount * 20 + 100))
    }
}

struct MarkdownToolbar: View {
    @Binding var text: String
    @FocusState private var textFieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Group {
                Button(action: { wrapSelection(with: "**") }) {
                    Image(systemName: "bold")
                }
                .help("Bold (⌘B)")
                .keyboardShortcut("b", modifiers: .command)

                Button(action: { wrapSelection(with: "_") }) {
                    Image(systemName: "italic")
                }
                .help("Italic (⌘I)")
                .keyboardShortcut("i", modifiers: .command)

                Button(action: { wrapSelection(with: "`") }) {
                    Image(systemName: "curlybraces")
                }
                .help("Inline Code")

                Divider()
                    .frame(height: 16)

                Button(action: { insertLink() }) {
                    Image(systemName: "link")
                }
                .help("Link (⌘K)")
                .keyboardShortcut("k", modifiers: .command)

                Button(action: { insertAtLineStart("- ") }) {
                    Image(systemName: "list.bullet")
                }
                .help("Bullet List")

                Button(action: { insertAtLineStart("1. ") }) {
                    Image(systemName: "list.number")
                }
                .help("Numbered List")

                Button(action: { insertCheckbox() }) {
                    Image(systemName: "checklist")
                }
                .help("Task List")

                Divider()
                    .frame(height: 16)

                Menu {
                    Button("Heading 1") { insertAtLineStart("# ") }
                    Button("Heading 2") { insertAtLineStart("## ") }
                    Button("Heading 3") { insertAtLineStart("### ") }
                    Button("Heading 4") { insertAtLineStart("#### ") }
                } label: {
                    Image(systemName: "textformat.size")
                }
                .help("Headings")

                Button(action: { insertAtLineStart("> ") }) {
                    Image(systemName: "quote.opening")
                }
                .help("Quote")

                Button(action: { insertCodeBlock() }) {
                    Image(systemName: "terminal")
                }
                .help("Code Block")

                Divider()
                    .frame(height: 16)

                Button(action: { insertTable() }) {
                    Image(systemName: "tablecells")
                }
                .help("Insert Table")

                Button(action: { insertHorizontalRule() }) {
                    Image(systemName: "minus")
                }
                .help("Horizontal Rule")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
        }
    }

    private func wrapSelection(with wrapper: String) {
        // In a real implementation, you'd get the selected text range
        // For now, just append at cursor position
        text = text + wrapper + "text" + wrapper
    }

    private func insertAtLineStart(_ prefix: String) {
        if text.isEmpty || text.hasSuffix("\n") {
            text = text + prefix
        } else {
            text = text + "\n" + prefix
        }
    }

    private func insertLink() {
        text = text + "[link text](https://example.com)"
    }

    private func insertCheckbox() {
        insertAtLineStart("- [ ] ")
    }

    private func insertCodeBlock() {
        if !text.isEmpty && !text.hasSuffix("\n") {
            text = text + "\n"
        }
        text = text + "```\ncode here\n```\n"
    }

    private func insertTable() {
        if !text.isEmpty && !text.hasSuffix("\n") {
            text = text + "\n"
        }
        text = text + """
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |

        """
    }

    private func insertHorizontalRule() {
        if !text.isEmpty && !text.hasSuffix("\n") {
            text = text + "\n"
        }
        text = text + "---\n"
    }
}

// Extension to help with text view customization
extension View {
    func introspect(customize: @escaping (NSViewRepresentable<HighlightedTextEditor>) -> Void) -> some View {
        self
    }
}