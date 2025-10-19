//
//  MarkdownEditorView.swift
//  Duey
//
//  Created by Xiao Xiao on 2025/10/19.
//

import SwiftUI
import SwiftData
import HighlightedTextEditor

struct MarkdownEditorView: View {
    @Bindable var task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Notes")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            HighlightedTextEditor(
                text: Binding(
                    get: { task.content ?? "" },
                    set: { task.content = $0.isEmpty ? nil : $0 }
                ),
                highlightRules: .markdown
            )
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(12)
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

