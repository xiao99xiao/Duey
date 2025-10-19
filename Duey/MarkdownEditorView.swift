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
            
            HighlightedTextEditor(
                text: Binding(
                    get: { task.content ?? "" },
                    set: { task.content = $0.isEmpty ? nil : $0 }
                ),
                highlightRules: .markdown
            )
            .introspect { editor in
                editor.textView.backgroundColor = .clear
            }
            .font(.system(.body, design: .monospaced))
            .padding(12)
        }
    }
}

