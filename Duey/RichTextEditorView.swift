//
//  RichTextEditorView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/26.
//

import SwiftUI
import SwiftData

struct RichTextEditorView: View {
    @Bindable var task: Task
    @State private var editingText: AttributedString = AttributedString("")
    @State private var hasLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RichTextEditor(text: $editingText)
                .padding(12)
                .onAppear {
                    if !hasLoaded {
                        // Load from model when view appears - parse markdown
                        if let markdown = task.content, !markdown.isEmpty {
                            do {
                                // Use .inlineOnlyPreservingWhitespace to preserve line breaks
                                editingText = try AttributedString(
                                    markdown: markdown,
                                    options: AttributedString.MarkdownParsingOptions(
                                        interpretedSyntax: .inlineOnlyPreservingWhitespace
                                    )
                                )
                            } catch {
                                // Fallback to plain text if markdown parsing fails
                                editingText = AttributedString(markdown)
                            }
                        } else {
                            editingText = AttributedString("")
                        }
                        hasLoaded = true
                    }
                }
                .onChange(of: editingText) { oldValue, newValue in
                    // Save to model on every change - convert to markdown
                    // Convert SwiftUI AttributedString → NSAttributedString → Markdown
                    if let nsAttributedString = try? NSAttributedString(newValue, including: \.appKit) {
                        task.content = DueyTextView.convertToMarkdown(nsAttributedString)
                    } else {
                        // Fallback to plain text
                        task.content = String(newValue.characters)
                    }
                }
        }
    }
}
