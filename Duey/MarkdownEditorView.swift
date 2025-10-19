//
//  MarkdownEditorView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData

struct MarkdownEditorView: View {
    @Bindable var task: Task
    @State private var showPreview = true

    var body: some View {
        HSplitView {
            // Editor
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

                TextEditor(text: Binding(
                    get: { task.content ?? "" },
                    set: { task.content = $0.isEmpty ? nil : $0 }
                ))
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(12)
            }
            .background(Color(NSColor.textBackgroundColor))

            // Preview
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
                        MarkdownPreview(content: task.content ?? "")
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
    }
}

struct MarkdownToolbar: View {
    @Binding var text: String
    @State private var selectedRange: NSRange?

    var body: some View {
        HStack(spacing: 8) {
            Group {
                Button(action: { insertMarkdown(prefix: "**", suffix: "**", placeholder: "bold text") }) {
                    Image(systemName: "bold")
                }
                .help("Bold")

                Button(action: { insertMarkdown(prefix: "_", suffix: "_", placeholder: "italic text") }) {
                    Image(systemName: "italic")
                }
                .help("Italic")

                Button(action: { insertMarkdown(prefix: "`", suffix: "`", placeholder: "code") }) {
                    Image(systemName: "curlybraces")
                }
                .help("Inline Code")

                Divider()
                    .frame(height: 16)

                Button(action: { insertMarkdown(prefix: "[", suffix: "](url)", placeholder: "link text") }) {
                    Image(systemName: "link")
                }
                .help("Link")

                Button(action: { insertMarkdown(prefix: "- ", suffix: "", placeholder: "list item") }) {
                    Image(systemName: "list.bullet")
                }
                .help("Bullet List")

                Button(action: { insertMarkdown(prefix: "1. ", suffix: "", placeholder: "numbered item") }) {
                    Image(systemName: "list.number")
                }
                .help("Numbered List")

                Divider()
                    .frame(height: 16)

                Menu {
                    Button("Heading 1") { insertMarkdown(prefix: "# ", suffix: "", placeholder: "Heading 1") }
                    Button("Heading 2") { insertMarkdown(prefix: "## ", suffix: "", placeholder: "Heading 2") }
                    Button("Heading 3") { insertMarkdown(prefix: "### ", suffix: "", placeholder: "Heading 3") }
                } label: {
                    Image(systemName: "textformat.size")
                }
                .help("Headings")

                Button(action: { insertMarkdown(prefix: "> ", suffix: "", placeholder: "quote") }) {
                    Image(systemName: "quote.opening")
                }
                .help("Quote")

                Button(action: { insertMarkdown(prefix: "```\n", suffix: "\n```", placeholder: "code block") }) {
                    Image(systemName: "terminal")
                }
                .help("Code Block")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
        }
    }

    private func insertMarkdown(prefix: String, suffix: String, placeholder: String) {
        text = prefix + placeholder + suffix
    }
}

struct MarkdownPreview: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdownLines(content), id: \.self) { line in
                renderLine(line)
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parseMarkdownLines(_ text: String) -> [String] {
        text.components(separatedBy: .newlines)
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        if line.hasPrefix("# ") {
            Text(String(line.dropFirst(2)))
                .font(.largeTitle)
                .fontWeight(.bold)
        } else if line.hasPrefix("## ") {
            Text(String(line.dropFirst(3)))
                .font(.title)
                .fontWeight(.semibold)
        } else if line.hasPrefix("### ") {
            Text(String(line.dropFirst(4)))
                .font(.title2)
                .fontWeight(.medium)
        } else if line.hasPrefix("> ") {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(width: 3)
                Text(String(line.dropFirst(2)))
                    .foregroundStyle(.secondary)
                Spacer()
            }
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .foregroundStyle(.secondary)
                Text(renderInlineMarkdown(String(line.dropFirst(2))))
                Spacer()
            }
        } else if let match = line.firstMatch(of: /^\d+\.\s+(.*)/) {
            HStack(alignment: .top, spacing: 8) {
                Text(String(line.prefix(while: { $0 != " " })))
                    .foregroundStyle(.secondary)
                Text(renderInlineMarkdown(String(match.1)))
                Spacer()
            }
        } else if line.hasPrefix("```") {
            // Code block marker - would need multi-line parsing for full support
            Text(line)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else if !line.isEmpty {
            Text(renderInlineMarkdown(line))
        }
    }

    private func renderInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString(text)

        // Bold
        if let regex = try? Regex("\\*\\*(.*?)\\*\\*") {
            for match in text.matches(of: regex).reversed() {
                if let range = Range(match.range, in: result) {
                    result.replaceSubrange(range, with: AttributedString(match.1, attributes: .init([
                        .font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
                    ])))
                }
            }
        }

        // Italic
        if let regex = try? Regex("_(.*?)_") {
            for match in text.matches(of: regex).reversed() {
                if let range = Range(match.range, in: result) {
                    var attrs = AttributedString(match.1)
                    attrs.obliqueness = 0.2
                    result.replaceSubrange(range, with: attrs)
                }
            }
        }

        // Inline code
        if let regex = try? Regex("`(.*?)`") {
            for match in text.matches(of: regex).reversed() {
                if let range = Range(match.range, in: result) {
                    var attrs = AttributedString(match.1)
                    attrs.font = .system(.body, design: .monospaced)
                    attrs.backgroundColor = Color(NSColor.controlBackgroundColor)
                    result.replaceSubrange(range, with: attrs)
                }
            }
        }

        return result
    }
}