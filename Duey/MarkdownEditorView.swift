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
                    get: { 
                        // Convert AttributedString to plain String for markdown editing
                        String(task.attributedContent.characters)
                    },
                    set: { newValue in
                        // Convert plain String back to AttributedString
                        task.attributedContent = newValue.isEmpty ? AttributedString("") : AttributedString(newValue)
                    }
                ),
                highlightRules: .markdown
            )
            .introspect { editor in
                editor.textView.drawsBackground = false
                editor.scrollView?.drawsBackground = false
            }
            .font(.system(.body, design: .monospaced))
            .padding(12)
        }
    }
}

